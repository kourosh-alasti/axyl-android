#!/bin/bash

CSV_FILE="links.csv"
GH_USER="kourosh-alasti"
GH_ORG="Modded-Android"

# Check if required tools are installed
command -v gh >/dev/null 2>&1 || { echo "Error: GitHub CLI (gh) is not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git is not installed"; exit 1; }

# Get absolute path of CSV file
CSV_FILE_PATH="$(cd "$(dirname "$CSV_FILE")" && pwd)/$(basename "$CSV_FILE")"

# Check if CSV file exists
if [[ ! -f "$CSV_FILE_PATH" ]]; then
    echo "Error: $CSV_FILE not found!"
    exit 1
fi

# Check if logged into GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
    echo "Error: Not logged into GitHub CLI. Please run 'gh auth login' first"
    exit 1
fi

convert_slash_to_dash() {
    echo "$1" | sed 's#^/##; s#/$##; s#/#-#g'
}

# Create working directory
WORK_DIR="temp_repos"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || { echo "Failed to create working directory"; exit 1; }

inc=1
# Skip header row and read links
tail -n +2 "$CSV_FILE_PATH" | while IFS= read -r link || [[ -n "$link" ]]; do
    # Skip empty lines
    [[ -z "$link" ]] && continue
    
    echo "Processing repository $inc: $link"
    
    # Create safe repository name
    new_repo_name="android-repo-${inc}"
    
    # Clone the repository
    echo "Cloning repository..."
    if ! git clone --quiet "https://android.googlesource.com${link}" "temp_${inc}"; then
        echo "Failed to clone repository: $link"
        continue
    fi
    
    cd "temp_${inc}" || { echo "Failed to enter repository directory"; continue; }
    
    # Remove .git and initialize new repository
    rm -rf .git
    git init --quiet
    git add .
    git commit -m "[Cursor] Initial commit of ${link}"
    
    # Create and push to new repository
    echo "Creating new repository: $new_repo_name"
    if ! gh repo create "$GH_ORG/$new_repo_name" --public --source=. --remote=origin; then
        echo "Failed to create repository: $new_repo_name"
        cd ..
        rm -rf "temp_${inc}"
        continue
    fi
    
    # Push to GitHub
    echo "Pushing to GitHub..."
    git branch -M main
    if ! git push -u origin main; then
        echo "Failed to push to repository: $new_repo_name"
    fi
    
    # Clean up
    cd ..
    rm -rf "temp_${inc}"
    
    echo "Completed processing repository $inc"
    ((inc++))
done

# Clean up working directory
cd ..
rm -rf "$WORK_DIR"

echo "Migration completed! Processed $((inc-1)) repositories."
