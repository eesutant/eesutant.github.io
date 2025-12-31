# PowerShell Script for Windows

$publicPath = "C:\blog\eesutant.github.io\public"
$docsPath = "C:\Blog\eesutant.github.io\docs"
$cnamePath = "C:\Blog\eesutant.github.io\docs\CNAME"

# Set Github repo 
$myrepo = "git@github.com:eesutant/eesutant.github.io.git"

# Set error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Change to the script's directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# Check for required commands
$requiredCommands = @('git', 'hugo')

foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd is not installed or not in PATH."
        exit 1
    }
}

# Step 1: Check if Git is initialized, and initialize if necessary
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
    git remote add origin $myrepo
} else {
    Write-Host "Git repository already initialized."
    $remotes = git remote
    if (-not ($remotes -contains 'origin')) {
        Write-Host "Adding remote origin..."
        git remote add origin $myrepo
    }
}

# Step 2: Build the Hugo site
Write-Host "Building the Hugo site..."
try {
    hugo
} catch {
    Write-Error "Hugo build failed."
    exit 1
}

# Step 3: Sync public to docs folder for use with Github Pages using Robocopy
Write-Host "Syncing public to docs..."

if (-not (Test-Path $publicPath)) {
    Write-Error "Public path does not exist: $publicPath"
    exit 1
}

if (-not (Test-Path $docsPath)) {
    Write-Error "Docs path does not exist: $docsPath"
    exit 1
}

# Use Robocopy to mirror the directories
$robocopyOptions = @('/MIR', '/Z', '/W:5', '/R:3', '/XF', $cnamePath)
$robocopyResult = robocopy $publicPath $docsPath @robocopyOptions

if ($LASTEXITCODE -ge 8) {
    Write-Error "Robocopy failed with exit code $LASTEXITCODE"
    exit 1
}

# Step 4: Add changes to Git
Write-Host "Staging changes for Git..."
$hasChanges = (git status --porcelain) -ne ""
if (-not $hasChanges) {
    Write-Host "No changes to stage."
} else {
    git add .
}

# Step 5: Commit changes with a dynamic message
$commitMessage = "New Blog Post on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$hasStagedChanges = (git diff --cached --name-only) -ne ""
if (-not $hasStagedChanges) {
    Write-Host "No changes to commit."
} else {
    Write-Host "Committing changes..."
    git commit -m "$commitMessage"
}

# Step 6: Push all changes to the main branch
Write-Host "Deploying to GitHub Main..."
try {
    git push origin main
} catch {
    Write-Error "Failed to push to Main branch."
    exit 1
}

Write-Host "All done! Site synced, processed, committed, built, and deployed."
