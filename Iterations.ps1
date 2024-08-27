param(
    [Parameter(Mandatory=$true)][String]$Organization,
    [Parameter(Mandatory=$true)][String]$PAT,
    [Parameter(Mandatory=$true)][String]$Project,
    [Parameter(Mandatory=$true)][String]$TeamName,
    [Parameter(Mandatory=$true)][String]$YearOfIteration,
    [Parameter(Mandatory=$true)][String]$MonthOfIteration,
    [Parameter(Mandatory=$true)][String]$StartDateOfIteration,
    [Parameter(Mandatory=$true)][String]$NumberOfSprints
)

Write-Host "`nValues provided to the script:"
Write-Host "Project: $Project"
Write-Host "Team: $TeamName"
Write-Host "YearOfIteration: $YearOfIteration"
Write-Host "MonthOfIteration: $MonthOfIteration"
Write-Host "StartDateOfIteration: $StartDateOfIteration"
Write-Host "NumberOfSprints: $NumberOfSprints`n"

# Set up the start date
$StartDate = Get-Date -Year $YearOfIteration -Month $MonthOfIteration -Day $StartDateOfIteration

# Log in to Azure DevOps
Write-Output $PAT | az devops login --org $Organization
Write-Host "`n===Configuring connection to organization and Team Project==="
az devops configure --defaults organization=$Organization project=$Project

# Get the existing sprints in the project
$ExistingIterations = az boards iteration project list --project $Project --org $Organization --depth 1 | ConvertFrom-Json

# Find the last sprint in the project to append the new ones after it
$LastIteration = $ExistingIterations | Sort-Object { $_.attributes.finishDate } -Descending | Select-Object -First 1
$ParentPath = $LastIteration.path

# Create new sprints sequentially
$StartDateIteration = $StartDate
For ($i = 1; $i -le $NumberOfSprints; $i++) {
    $SprintNumber = "{0:D2}" -f $i + ($StartDate.Year.ToString().Substring(2, 2))
    $SprintName = "Sprint $SprintNumber"
    $FinishDateIteration = $StartDateIteration.AddDays(13)
    $createIteration = az boards iteration project create --name $SprintName --path $ParentPath --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json
    $addIteration = az boards iteration team add --id $createIteration.identifier --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
    Write-Host "$($addIteration.name) created on path $($addIteration.path)"
    $StartDateIteration = $FinishDateIteration.AddDays(1)
}

# Log out from Azure DevOps
az devops logout


