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

inc=1
while IFS= read -r link || [[ -n "$link" ]]; do
    echo "Starting migration for $link"
    converted_name=$(convert_slash_to_dash $link)
    echo "$converted_name"

    repo_name=$(basename -s .git "$link")
    new_repo_name="repo-$inc"
    
    # Clone the repo
    echo "Cloning $repo_name..."
    git clone "https://android.googlesource.com$link" "$link"
    cd "$repo_name" || { echo "Failed to navigate to $repo_name"; exit 1; }

    echo "Remove .git directory"
    rm -rf .git

    echo "Initialize New Repo"
    git init
    git add .
    git commit -m "initial commit"

   echo "create new repo for $GH_ORG"
   gh repo create "https://github.com/$GH_ORG/$new_repo_name" --public --source=. --remote=origin

   echo "Push to GitHub"
   git branch -M master
   git push -u origin master

   cd ..
   echo "Removing local folder $repo_name"
   rm -rf "$repo_name"

   ((inc++))

done < "$CSV_FILE"

echo "Migration Completed!"
