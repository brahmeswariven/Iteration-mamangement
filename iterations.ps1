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

# Auto setting variables based on values provided
$StartDate = Get-Date -Year $YearOfIteration -Month $MonthOfIteration -Day $StartDateOfIteration

# Execution begins
Write-Output $PAT | az devops login --org $Organization
Write-Host "`n===Configuring connection to organization and Team Project==="
az devops configure --defaults organization=$Organization project=$Project

$StartDateIteration = $StartDate
For ($i=1; $i -le $NumberOfSprints; $i++) 
{
    $Sprint = "Sprint " + "{0:D2}" -f $i + ($StartDate.Year.ToString().Substring(2, 2))
    $FinishDateIteration = $StartDateIteration.AddDays(13)

    # Correctly format the path without leading slashes
    $IterationPath = "$Project\Iteration"

    $createIteration = az boards iteration project create --name $Sprint --path $IterationPath --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json

    # Ensure you're using the correct ID for the created iteration
    if ($createIteration.Identifier) {
        $addIteration = az boards iteration team add --id $createIteration.id --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
        Write-Host "$($addIteration.name) created on path $($addIteration.path)"
    } else {
        Write-Host "Failed to create iteration."
    }

    $StartDateIteration = $FinishDateIteration.AddDays(1)
}

az devops logout

