# Azure Project Template

Production-ready Azure project template with multiple architecture options.

## Quick Start

### 1. Create from Template
\\\ash
gh repo create myorg/my-project --template phoenixvc/azure-project-template --public --clone
cd my-project
\\\

### 2. Choose Architecture
\\\ash
# Standard (fast development)
cp -r src/api-standard src/api

# OR Hexagonal (clean architecture)
cp -r src/api-hexagonal src/api

# Clean up
rm -rf src/api-standard src/api-hexagonal
\\\

### 3. Configure
\\\ash
# Edit infrastructure parameters
code infra/parameters/dev.bicepparam
\\\

### 4. Deploy
\\\ash
az deployment sub create --location westeurope --template-file infra/main.bicep --parameters infra/parameters/dev.bicepparam
\\\

### 5. Run Locally
\\\ash
cd src/api
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
\\\

## Architecture Options

### Standard (Layered)
**Best for:** Quick development, MVPs, simple CRUD

- Fast development
- Easy to understand
- Simple structure

### Hexagonal (Clean Architecture)
**Best for:** Complex business logic, long-term projects

- Highly testable
- Easy to maintain
- Clear separation of concerns

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Project Structure
\\\
├── infra/           # Bicep templates
├── src/             # Source code
│   ├── api-standard/
│   ├── api-hexagonal/
│   └── web/
├── config/          # Environment configs
├── db/              # Migrations & seeds
└── tests/           # Unit, integration, E2E
\\\

## Testing
\\\ash
pytest tests/unit -v
pytest tests/integration -v
pytest tests/e2e -v
\\\

## Related
- [azure-infrastructure](https://github.com/phoenixvc/azure-infrastructure) - Standards & modules

Built with ❤️ by Phoenix VC
