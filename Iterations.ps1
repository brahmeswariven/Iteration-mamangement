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

# Set up the start date and paths
$StartDate = Get-Date -Year $YearOfIteration -Month $MonthOfIteration -Day $StartDateOfIteration
$RootPath = "\" + $Project + "\Iteration\" + $StartDate.Year
$ParentIteration = "\" + $Project + "\Iteration"

# Log in to Azure DevOps
Write-Output $PAT | az devops login --org $Organization
Write-Host "`n===Configuring connection to organization and Team Project==="
az devops configure --defaults organization=$Organization project=$Project

# Get existing iterations
$ListOfIterations = az boards iteration project list --depth 1 | ConvertFrom-Json

# Check if the root folder exists
if ($ListOfIterations.children.name -contains $StartDate.Year) {
    Write-Host "`n$($StartDate.Year) path already exists and won't be created."
} else {
    Write-Host "`n$($StartDate.Year) does not exist and will be created."
    $CreateRootIteration = az boards iteration project create --name $StartDate.Year --path $ParentIteration | ConvertFrom-Json
    # Comment out or remove the following line to avoid displaying the created root path message
    # Write-Host 'Created Root path: '$CreateRootIteration.name
}

# Create new sprints sequentially
$StartDateIteration = $StartDate
For ($i = 1; $i -le $NumberOfSprints; $i++) {
    $Sprint = "Sprint " + "{0:D2}" -f $i + ($StartDate.Year.ToString().Substring(2, 2))
    $FinishDateIteration = $StartDateIteration.AddDays(13)
    $createIteration = az boards iteration project create --name $Sprint --path $RootPath --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json
    $addIteration = az boards iteration team add --id $createIteration.Identifier --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
    Write-Host $addIteration.name 'created on path'$addIteration.path
    $StartDateIteration = $FinishDateIteration.AddDays(1)
}

# Log out from Azure DevOps
az devops logout
