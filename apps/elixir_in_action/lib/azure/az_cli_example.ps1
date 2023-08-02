$ErrorActionPreference = 'Stop'
# setup temporary profile path for the alternative user
$altIdProfilePath = Join-Path ([io.path]::GetTempPath()) '.azure-altId'

try {
    # check whether already logged-in
    $currentToken = $(az account get-access-token) | ConvertFrom-Json
    if ([datetime]$currentToken.expiresOn -le [datetime]::Now) {
        throw
    }
}
catch {
    Write-Host 'You need to login'
    az login | Out-Null
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Host "You are logged-in (default credential)"
Write-Host "Output from 'az account show':"
az account show --query user

# create a test SPN
Write-Host "`nCreating temporary SPN..."
$newUser = $(az ad sp create-for-rbac -n "My-Alt-Id" --skip-assignment) | ConvertFrom-Json
Write-Host "Created appId: $($newUser.appId)"

Write-Host "`nSwitching to alternative user ($altIdProfilePath)"
# don't use the new SPN too soon ;-)
Start-Sleep -Seconds 5
$env:AZURE_CONFIG_DIR = $altIdProfilePath
Write-Host "Logging-in as temporary SPN"
az login --service-principal -u $newUser.appId -p $newUser.password --tenant $newUser.tenant --allow-no-subscriptions | Out-Null
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "Output from 'az account show':"
az account show --query user

Write-Host "`nSwitching back to default credential"
# unset the environment variable
Remove-Item env:\AZURE_CONFIG_DIR
Write-Host "Output from 'az account show':"
az account show --query user

# tidy-up
Write-Host "`nRemoving temporary SPN..."
az ad sp delete --id $newUser.appId
Remove-Item -Recurse -Force $altIdProfilePath