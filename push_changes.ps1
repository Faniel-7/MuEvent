# push_changes.ps1
# Usage: run in repo root in PowerShell. The script will prompt for branch and commit message.

# Check we're inside a git repo
$inside = & git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') {
    Write-Error "This directory is not a git repository. Run this script from the repo root."
    exit 1
}

$defaultBranch = 'feature/layout-iframe-mobile-fixes'
$branch = Read-Host "Branch name (enter to use '$defaultBranch')"
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = $defaultBranch }

# Try to create or switch to branch
Write-Host "Switching to branch '$branch'..."
$checkout = & git checkout $branch 2>&1
if ($LASTEXITCODE -ne 0) {
    # try creating the branch
    $create = & git checkout -b $branch 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create or switch to branch '$branch'. Details:`n$create"
        exit 1
    }
}

# Stage all changes
Write-Host "Staging all changes..."
& git add -A

# Check if there are staged changes
$changes = & git diff --cached --name-only
if ([string]::IsNullOrWhiteSpace($changes)) {
    Write-Host "No changes staged to commit. If you want to push an existing branch, continuing to push..."
    $pushNow = Read-Host "Push branch '$branch' to remote 'origin'? (y/N)"
    if ($pushNow -ne 'y') { Write-Host "Aborting."; exit 0 }
    # ensure remote origin exists
    $remote = & git remote
    if ([string]::IsNullOrWhiteSpace($remote)) {
        $url = Read-Host "No remote found. Enter remote URL to add as 'origin' (or empty to abort)"
        if ([string]::IsNullOrWhiteSpace($url)) { Write-Error "No remote provided. Aborting."; exit 1 }
        & git remote add origin $url
    }
    Write-Host "Pushing branch '$branch' to origin..."
    & git push -u origin $branch
    exit $LASTEXITCODE
}

# Commit message defaults
$defaultTitle = 'feat(layout): three-column layout + mobile fixes'
$defaultBody  = "Left nav loads pages into center iframe; icons clickable on mobile; enabled center scrolling and removed auto-resize. Added right-panel separator and placeholder panes under /panes."

$title = Read-Host "Commit title (enter to use default: $defaultTitle)"
if ([string]::IsNullOrWhiteSpace($title)) { $title = $defaultTitle }

Write-Host "Enter a short commit body (press Enter to use default). Finish input with Enter."
$body = Read-Host "Commit body"
if ([string]::IsNullOrWhiteSpace($body)) { $body = $defaultBody }

# Commit
Write-Host "Creating commit..."
& git commit -m "$title" -m "$body"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Git commit failed. Please fix the problem and try again."
    exit 1
}

# Ensure remote exists
$remote = & git remote
if ([string]::IsNullOrWhiteSpace($remote)) {
    $url = Read-Host "No remote found. Enter remote URL to add as 'origin' (or empty to abort)"
    if ([string]::IsNullOrWhiteSpace($url)) { Write-Error "No remote provided. Aborting."; exit 1 }
    & git remote add origin $url
}

# Push
Write-Host "Pushing branch '$branch' to origin..."
& git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed. Resolve any errors (auth, network, or branch protection) and try again."
    exit 1
}

Write-Host "Push complete. Open a Pull Request on your remote repository to merge '$branch' into 'main'."
