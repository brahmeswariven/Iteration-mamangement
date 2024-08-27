param(
    [Parameter(Mandatory=$true)][String]$Organization,
    [Parameter(Mandatory=$true)][String]$PAT,
    [Parameter(Mandatory=$true)][String[]]$Projects,
    [Parameter(Mandatory=$true)][String]$TeamName,
    [Parameter(Mandatory=$true)][String]$YearOfIteration,
    [Parameter(Mandatory=$true)][String]$MonthOfIteration,
    [Parameter(Mandatory=$true)][String]$StartDateOfIteration,
    [Parameter(Mandatory=$true)][String]$NumberOfSprints
)

Write-Host "`nValues provided to the script:"
Write-Host "Projects: $Projects"
Write-Host "Team: $TeamName"
Write-Host "YearOfIteration: $YearOfIteration"
Write-Host "MonthOfIteration: $MonthOfIteration"
Write-Host "StartDateOfIteration: $StartDateOfIteration"
Write-Host "NumberOfSprints: $NumberOfSprints`n"

# Set up the start date
$StartDate = Get-Date -Year $YearOfIteration -Month $MonthOfIteration -Day $StartDateOfIteration

# Log in to Azure DevOps
Write-Output $PAT | az devops login --org $Organization
Write-Host "`n===Configuring connection to organization==="
az devops configure --defaults organization=$Organization

foreach ($Project in $Projects) {
    Write-Host "`nProcessing project: $Project"

    # Fetch existing iterations to find the root path
    $iterations = az boards iteration project list --project $Project --depth 1 | ConvertFrom-Json

    # Find the root path (assuming the root path is the one with no parent path)
    $RootPath = ($iterations.value | Where-Object { $_.path -match '^\\' }).path

    if (-not $RootPath) {
        Write-Host "`nRoot path not found for project: $Project"
        continue
    }

    Write-Host "`nUsing root path: $RootPath"

    # Create new sprints sequentially
    $StartDateIteration = $StartDate
    For ($i = 1; $i -le $NumberOfSprints; $i++) {
        $Sprint = "Sprint " + "{0:D2}" -f $i + ($StartDate.Year.ToString().Substring(2, 2))
        $FinishDateIteration = $StartDateIteration.AddDays(13)
        
        # Create iteration
        $createIteration = az boards iteration project create --name $Sprint --path $RootPath --start-date $StartDateIteration --finish-date $FinishDateIteration --project $Project --org $Organization | ConvertFrom-Json

        # Add iteration to team
        if ($createIteration.Identifier) {
            $addIteration = az boards iteration team add --id $createIteration.Identifier --team $TeamName --project $Project --org $Organization | ConvertFrom-Json
            Write-Host $addIteration.name 'created on path' $addIteration.path
        } else {
            Write-Host "Failed to create iteration: $Sprint"
        }
        
        # Update start date for the next sprint
        $StartDateIteration = $FinishDateIteration.AddDays(1)
    }
}

# Log out from Azure DevOps
az devops logout


