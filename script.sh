#!/bin/bash

CSV_FILE="links.csv"
GH_USER="kourosh-alasti"
GH_ORG="Modded-Android"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: $CSV_FILE not found!"
    exit 1
fi

convert_slash_to_dash() {
    echo "$1" | sed 's#^/##; s#/$##; s#/#-#g'
}

while IFS= read -r link || [[ -n "$link" ]]; do
    echo "Starting migration for $link"
    echo $(convert_slash_to_dash $link)

    
    repo_name=$(basename -s .git "$link")

    # Clone the repo
    echo "Cloning $repo_name..."
    git clone "https://android.googlesource.com$link" "$repo_name"
    cd "$repo_name" || { echo "Failed to navigate to $repo_name"; exit 1; }

    echo "Remove .git directory"
    rm -rf .git

    echo "Initialize New Repo"
    git init
    git add .
    git commit -m "initial commit"

   echo "create new repo for $GH_ORG"
   gh repo create "https://github.com/$GH_ORG/$(convert_slash_to_dash $link)" --public --source=. --remote=origin

   echo "Push to GitHub"
   git branch -M master
   git push -u origin master

   cd ..
   echo "Removing local folder $repo_name"
   rm -rf "$repo_name"

done < "$CSV_FILE"

echo "Migration Completed!"