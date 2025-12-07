# Phoenix Project Initializer - GitHub App

A GitHub App that automates project initialization when repositories are created from the azure-project-template.

## Features

- **Auto-detection**: Detects when repos are created from the template
- **Smart initialization**: Auto-configures if repo name follows the pattern
- **Slash commands**: Users can run `/init` in issues to configure
- **Workflow integration**: Triggers the initialization workflow
- **Issue management**: Creates setup issues and closes them on completion

## Setup

### 1. Create a GitHub App

1. Go to **GitHub Settings** → **Developer settings** → **GitHub Apps**
2. Click **New GitHub App**
3. Fill in:
   - **Name**: `Phoenix Project Initializer`
   - **Homepage URL**: Your org URL
   - **Webhook URL**: `https://your-app.azurewebsites.net/api/webhook`
   - **Webhook secret**: Generate a secure secret
4. Set permissions:
   - **Repository permissions**:
     - Actions: Read & write
     - Contents: Read
     - Issues: Read & write
     - Metadata: Read
   - **Organization permissions**:
     - Members: Read (optional, for team-based access)
5. Subscribe to events:
   - `Repository`
   - `Issue comment`
   - `Workflow run`
6. Click **Create GitHub App**
7. Generate and download the private key

### 2. Install the App

1. Go to your GitHub App settings
2. Click **Install App**
3. Select your organization
4. Choose **All repositories** or select specific repos

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values:
- `APP_ID`: From GitHub App settings
- `WEBHOOK_SECRET`: The secret you set
- `PRIVATE_KEY`: Base64 encoded private key

### 4. Deploy to Azure

#### Option A: Azure Container Apps (Recommended)

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-phoenix-github-app --location westeurope

# Create Container Apps environment
az containerapp env create \
  --name phoenix-github-app-env \
  --resource-group rg-phoenix-github-app \
  --location westeurope

# Build and push to Azure Container Registry
az acr build --registry <your-acr> --image phoenix-github-app:latest .

# Deploy Container App
az containerapp create \
  --name phoenix-github-app \
  --resource-group rg-phoenix-github-app \
  --environment phoenix-github-app-env \
  --image <your-acr>.azurecr.io/phoenix-github-app:latest \
  --target-port 3000 \
  --ingress external \
  --env-vars \
    APP_ID=secretref:app-id \
    WEBHOOK_SECRET=secretref:webhook-secret \
    PRIVATE_KEY=secretref:private-key
```

#### Option B: Azure App Service

```bash
# Create App Service Plan
az appservice plan create \
  --name phoenix-github-app-plan \
  --resource-group rg-phoenix-github-app \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name phoenix-github-app \
  --resource-group rg-phoenix-github-app \
  --plan phoenix-github-app-plan \
  --runtime "NODE:20-lts"

# Configure environment variables
az webapp config appsettings set \
  --name phoenix-github-app \
  --resource-group rg-phoenix-github-app \
  --settings \
    APP_ID="your-app-id" \
    WEBHOOK_SECRET="your-secret" \
    PRIVATE_KEY="base64-encoded-key"

# Deploy from local
az webapp up --name phoenix-github-app
```

#### Option C: Azure Functions

```bash
# Create Function App
az functionapp create \
  --name phoenix-github-app-func \
  --resource-group rg-phoenix-github-app \
  --storage-account <storage-account> \
  --consumption-plan-location westeurope \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4

# Deploy
func azure functionapp publish phoenix-github-app-func
```

#### Option D: Local Development

```bash
# Install smee for webhook forwarding
npm install -g smee-client

# Create a channel at https://smee.io
smee -u https://smee.io/YOUR_CHANNEL -t http://localhost:3000/api/webhook

# In another terminal
npm install
npm run dev
```

## Infrastructure as Code

### Bicep Deployment

```bicep
// infra/github-app.bicep
param location string = 'westeurope'
param appName string = 'phoenix-github-app'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: 'B1'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appSettings: [
        { name: 'APP_ID', value: '@Microsoft.KeyVault(SecretUri=...)' }
        { name: 'WEBHOOK_SECRET', value: '@Microsoft.KeyVault(SecretUri=...)' }
        { name: 'PRIVATE_KEY', value: '@Microsoft.KeyVault(SecretUri=...)' }
      ]
    }
  }
}

output url string = 'https://${webApp.properties.defaultHostName}'
```

Deploy:
```bash
az deployment group create \
  --resource-group rg-phoenix-github-app \
  --template-file infra/github-app.bicep
```

## Usage

### Automatic Initialization

When a user creates a repo named like `nl-dev-myapp-fastapi`, the app automatically:
1. Detects the template usage
2. Parses the repo name
3. Triggers the initialization workflow

### Manual Initialization

For repos with any name:
1. User creates repo from template
2. App creates a setup issue
3. User replies with `/init org=nl env=dev project=myapp stack=fastapi`
4. App triggers the workflow
5. Issue is closed on success

## Slash Commands

```
/init org=<org> env=<env> project=<name> stack=<stack> [region=<region>]
```

**Example:**
```
/init org=nl env=dev project=myapi stack=fastapi region=euw
```

## Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build for production
npm run build

# Run tests
npm test
```

## CI/CD Pipeline

The app includes a GitHub Actions workflow for deployment to Azure:

```yaml
# .github/workflows/deploy-github-app.yml
name: Deploy GitHub App

on:
  push:
    branches: [main]
    paths:
      - 'platform/github-app/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and Deploy
        uses: azure/webapps-deploy@v2
        with:
          app-name: phoenix-github-app
          package: platform/github-app
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐
│  GitHub Events  │────▶│   GitHub App     │
└─────────────────┘     │  (Azure hosted)  │
                        └────────┬─────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        ▼                        ▼                        ▼
┌───────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ repo.created  │      │ issue_comment   │      │ workflow_run    │
│               │      │ (/init command) │      │ (completed)     │
└───────┬───────┘      └────────┬────────┘      └────────┬────────┘
        │                       │                        │
        ▼                       ▼                        ▼
┌───────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ Create Issue  │      │ Trigger         │      │ Close Setup     │
│ or Auto-Init  │      │ Workflow        │      │ Issues          │
└───────────────┘      └─────────────────┘      └─────────────────┘
```

## Monitoring

### Azure Application Insights

Add Application Insights for monitoring:

```bash
az monitor app-insights component create \
  --app phoenix-github-app-insights \
  --location westeurope \
  --resource-group rg-phoenix-github-app

# Get connection string and add to app settings
az webapp config appsettings set \
  --name phoenix-github-app \
  --resource-group rg-phoenix-github-app \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="..."
```

### Health Check

The app exposes a health endpoint at `/health` for Azure monitoring.

## Security

- Store secrets in **Azure Key Vault**
- Use **Managed Identity** for Key Vault access
- Enable **HTTPS only** on App Service
- Configure **IP restrictions** if needed
