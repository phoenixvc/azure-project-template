$ErrorActionPreference = "Stop"

Write-Host "`n🔧 Adding complete implementations..." -ForegroundColor Cyan

# ============================================================================
# 1. Hexagonal API - User Repository
# ============================================================================
Write-Host "`n📝 Completing Hexagonal API..." -ForegroundColor Yellow

"from abc import ABC, abstractmethod`nfrom typing import Optional`nfrom domain.entities.user import User`n`nclass UserRepository(ABC):`n    async def create(self, user: User) -> User:`n        pass`n    async def get_by_id(self, user_id: int) -> Optional[User]:`n        pass" | Out-File src/api-hexagonal/domain/repositories/user_repository.py -Encoding UTF8

"fastapi==0.109.0`nuvicorn[standard]==0.27.0`npydantic==2.5.3`nsqlalchemy==2.0.25`nasyncpg==0.29.0" | Out-File src/api-hexagonal/requirements.txt -Encoding UTF8

"# API - Hexagonal Architecture`n`nClean architecture with DDD.`n`n## Run`npip install -r requirements.txt`nuvicorn adapters.api.main:app --reload" | Out-File src/api-hexagonal/README.md -Encoding UTF8

Write-Host "  ✓ Hexagonal API" -ForegroundColor Green

# ============================================================================
# 2. Standard API
# ============================================================================
Write-Host "`n📝 Standard API..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "src/api-standard" -Force | Out-Null

"from fastapi import FastAPI`napp = FastAPI()`n`n@app.get('/')`nasync def root():`n    return {'message': 'API Standard'}`n`n@app.get('/health')`nasync def health():`n    return {'status': 'healthy'}" | Out-File src/api-standard/main.py -Encoding UTF8

"fastapi==0.109.0`nuvicorn[standard]==0.27.0" | Out-File src/api-standard/requirements.txt -Encoding UTF8

"# API - Standard`n`n## Run`npip install -r requirements.txt`nuvicorn main:app --reload" | Out-File src/api-standard/README.md -Encoding UTF8

Write-Host "  ✓ Standard API" -ForegroundColor Green

# ============================================================================
# 3. Config
# ============================================================================
Write-Host "`n📝 Config files..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "config" -Force | Out-Null

'{"org":"nl","env":"dev","project":"myproject","region":"euw"}' | Out-File config/dev.json -Encoding UTF8
'{"org":"nl","env":"staging","project":"myproject","region":"euw"}' | Out-File config/staging.json -Encoding UTF8
'{"org":"nl","env":"prod","project":"myproject","region":"euw"}' | Out-File config/prod.json -Encoding UTF8

Write-Host "  ✓ Config" -ForegroundColor Green

# ============================================================================
# 4. Database
# ============================================================================
Write-Host "`n📝 Database..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "db/migrations","db/seeds" -Force | Out-Null

"CREATE TABLE users (id SERIAL PRIMARY KEY, email VARCHAR(255) UNIQUE NOT NULL);" | Out-File db/migrations/001_initial_schema.sql -Encoding UTF8
"INSERT INTO users (email) VALUES ('dev@example.com');" | Out-File db/seeds/dev_data.sql -Encoding UTF8
"# Database`n`nMigrations and seeds" | Out-File db/README.md -Encoding UTF8

Write-Host "  ✓ Database" -ForegroundColor Green

# ============================================================================
# 5. Tests
# ============================================================================
Write-Host "`n📝 Tests..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "tests/unit","tests/integration","tests/e2e" -Force | Out-Null

"# Unit Tests" | Out-File tests/unit/README.md -Encoding UTF8
"# Integration Tests" | Out-File tests/integration/README.md -Encoding UTF8
"# E2E Tests" | Out-File tests/e2e/README.md -Encoding UTF8

Write-Host "  ✓ Tests" -ForegroundColor Green

# ============================================================================
# 6. Docs
# ============================================================================
Write-Host "`n📝 Documentation..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "docs" -Force | Out-Null

@"
# Azure Project Template

Production-ready template with multiple architectures.

## Quick Start
1. Use this template
2. Choose architecture (Standard or Hexagonal)
3. Configure infra/parameters/dev.bicepparam
4. Deploy

## Architecture Options
- Standard: Fast, simple layered architecture
- Hexagonal: Clean architecture with DDD

## References
- [Azure Infrastructure](https://github.com/phoenixvc/azure-infrastructure)
"@ | Out-File README.md -Encoding UTF8

@"
# Architecture Guide

## Standard (Layered)
- Fast development
- Simple structure

## Hexagonal (Clean)
- Complex business logic
- Long-term maintainability
"@ | Out-File docs/ARCHITECTURE.md -Encoding UTF8

Write-Host "  ✓ Docs" -ForegroundColor Green

# ============================================================================
# 7. .gitignore
# ============================================================================
Write-Host "`n📝 .gitignore..." -ForegroundColor Yellow

"__pycache__/`nnode_modules/`n.env`n.vscode/`n*.log`n.DS_Store" | Out-File .gitignore -Encoding UTF8

Write-Host "  ✓ .gitignore" -ForegroundColor Green

# ============================================================================
# 8. Commit
# ============================================================================
Write-Host "`n📤 Committing..." -ForegroundColor Yellow

git add .
git commit -m "Complete template implementation"
git push

Write-Host "`n✅ Done!" -ForegroundColor Green
Write-Host "📍 https://github.com/phoenixvc/azure-project-template" -ForegroundColor Cyan
