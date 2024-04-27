# Passbox
A simple app for securely transferring files within a small team. TODO: Migrating to Azure Function Apps to reduce costs from ~$10/mo to virtually free for hobbyists/small businesses.
## Quickstart
1. Update `users.json` to configure user credentials
2. Run `deploy.ps1`
```PowerShell
./deploy.ps1
```
### Requirements
1. PowerShell (start script)
2. Azure CLI (deployment commands)
3. Python (deployment tools)
4. Azure (cloud resources)
5. Flask (framework)
### Azure Resources
1. App Service (linux/webapp)
2. App Service Plan (B1)
3. Storage Account (Standard LRS)
### File Structure
```yaml
Azure Template/
  - app/
	- app.py
	- requirements.txt
  - scripts/
    - upload_static.py
  - static/
    - index.html
    - users.json
  - deploy.ps1
  - README.md
  - resources.bicep
```