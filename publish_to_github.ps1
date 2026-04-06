# Build the site
hugo

# Path to your GitHub Pages repo
$repo = "C:\blog\eesutant.github.io"

# Remove everything in the repo EXCEPT CNAME
Get-ChildItem -Path $repo -Exclude "CNAME" | Remove-Item -Recurse -Force

# Copy the new public/ output into the repo
Copy-Item -Path ".\public\*" -Destination $repo -Recurse -Force

# Go to the repo
Set-Location $repo

# Commit and push
git add .
git commit -m "Publish site"
git push
Set-Location "C:\blog\wordsoflifelibrary"
