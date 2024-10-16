param(
    [Parameter(Mandatory=$true)][String]$Organization,
    [Parameter(Mandatory=$true)][String]$PAT,
    [Parameter(Mandatory=$true)][String]$Project,
    [Parameter(Mandatory=$true)][String]$TeamName,
    [Parameter(Mandatory=$true)][Int]$StartingSprintNumber,   # Starting Sprint Number (e.g., 21 if starting from Sprint 2124)
    [Parameter(Mandatory=$true)][Int]$StartingYear,           # Starting Year (e.g., 24 for 2024)
    [Parameter(Mandatory=$true)][Int]$NumberOfSprints         # Number of new sprints to create
)

Write-Host "`nValues provided to the script:"
Write-Host "Project: $Project"
Write-Host "Team: $TeamName"
Write-Host "Starting Sprint Number: $StartingSprintNumber"
Write-Host "Starting Year: $StartingYear"
Write-Host "Number Of Sprints: $NumberOfSprints`n"

# Log in to Azure DevOps
Write-Output $PAT | az devops login --org $Organization
Write-Host "`n===Configuring connection to organization and Team Project==="
az devops configure --defaults organization=$Organization project=$Project

# Get the existing sprints in the project
$ExistingIterations = az boards iteration project list --project $Project --org $Organization --depth 1 | ConvertFrom-Json

# Find the last sprint in the project to append the new ones after it
$LastIteration = $ExistingIterations | Sort-Object { $_.attributes.finishDate } -Descending | Select-Object -First 1
$ParentPath = $LastIteration.path
$StartDateIteration = [datetime]::Parse($LastIteration.attributes.finishDate).AddDays(1)  # Start next sprint the day after last one finishes

# Initialize sprint number and year
$CurrentSprintNumber = $StartingSprintNumber
$CurrentYear = $StartingYear

# Create new sprints sequentially
For ($i = 1; $i -le $NumberOfSprints; $i++) {

    # Calculate sprint name (e.g., Sprint 2124, Sprint 0125)
    $SprintName = "Sprint $($CurrentSprintNumber.ToString('D2'))$($CurrentYear.ToString())"

    # Check if sprint already exists
    $ExistingSprints = $ExistingIterations | Where-Object { $_.name -eq $SprintName }
    if ($ExistingSprints) {
        Write-Host "Sprint $SprintName already exists, skipping creation."
        Continue
    }

    # Calculate finish date for the new sprint (2-week sprint)
    $FinishDateIteration = $StartDateIteration.AddDays(14)

    # Create new sprint and assign it to the team
    $createIteration = az boards iteration project create --name $SprintName --path $ParentPath --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json
    $addIteration = az boards iteration team add --id $createIteration.identifier --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
    Write-Host "$($addIteration.name) created on path $($addIteration.path)"

    # Set up next sprint start date (day after current sprint finish)
    $StartDateIteration = $FinishDateIteration.AddDays(1)

    # Increment sprint number
    $CurrentSprintNumber++

    # If sprint number exceeds 26, reset to 01 and increment the year
    If ($CurrentSprintNumber -gt 26) {
        $CurrentSprintNumber = 1
        $CurrentYear++
    }
}

# Log out from Azure DevOps
az devops logout



