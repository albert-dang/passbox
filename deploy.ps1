function Stop-OnError {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "An error occurred: $Error[0]" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

$project = "passbox"
$location = "centralus"
$hostname = "${project}.example.com"
$resourceGroupName = "rg-${project}-${location}"
$appName = "app-${project}-${location}"

Write-Host "Creating $resourceGroupName in $location ..." -ForegroundColor Cyan
az group create --name $resourceGroupName --location $location
Stop-OnError

Write-Host "Deploying resources ..." -ForegroundColor Cyan
$deploymentOutput = az deployment group create --resource-group $resourceGroupName --template-file ./resources.bicep --parameters project=$project location=$location hostname=$hostname --query "properties.outputs"
Stop-OnError

$storageConnectionString = ($deploymentOutput | ConvertFrom-Json).storageConnectionString.value

Write-Host "Uploading static content to the storage account ..." -ForegroundColor Cyan
python ./scripts/upload_static.py "$storageConnectionString"
Stop-OnError

$appZipPath = ".\app.zip"
if (Test-Path $appZipPath) {
    Write-Host "Clean existing app.zip ..." -ForegroundColor Cyan
    Remove-Item $appZipPath
}
Stop-OnError

Write-Host "Compressing app files ..." -ForegroundColor Cyan
Compress-Archive -Path .\app\* -DestinationPath $appZipPath
Stop-OnError

Write-Host "Deploying app.zip to $appName ..." -ForegroundColor Cyan
az webapp deployment source config-zip --resource-group $resourceGroupName --name $appName --src $appZipPath
Stop-OnError

Write-Host "Deployment completed." -ForegroundColor Green