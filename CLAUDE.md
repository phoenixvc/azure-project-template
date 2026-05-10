# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**azure-project-template** — Reusable Azure project scaffolding supporting both standard and hexagonal (clean) architecture patterns for FastAPI applications on Azure.

## Status: Under Review

This repo is a generated output of [`azure-infrastructure`](https://github.com/JustAGhosT/azure-infrastructure)'s PowerShell scripts. A consolidation review is pending to determine whether this should remain standalone or be archived in favor of the parent repo. See also: integration with `codeflow-azure-setup` and `agentkit-forge`.

## Tech Stack

- **Backend**: Python (FastAPI)
- **IaC**: Bicep (`infra/`)
- **Database**: Setup in `db/`
- **Scripts**: PowerShell (`complete-template.ps1`)

## Key Commands

```powershell
./complete-template.ps1    # Generate/complete template scaffolding
```

```bash
cd src && pip install -r requirements.txt   # Install Python deps
cd tests && pytest                          # Run tests
```

## Architecture

- `src/` — Application source (FastAPI)
- `infra/` — Bicep templates for Azure resources
- `config/` — Environment and app configuration
- `db/` — Database migrations and setup
- `tests/` — Test suite

## Related Repos

- **[`azure-infrastructure`](https://github.com/JustAGhosT/azure-infrastructure)** — Parent repo whose PowerShell generators produce this template
- **`codeflow-azure-setup`** — Generic Azure bootstrap scripts
- **`codeflow-infrastructure`** — CodeFlow-specific production IaC

## AgentKit Forge

This project has not yet been onboarded to [AgentKit Forge](https://github.com/phoenixvc/agentkit-forge). To request onboarding, [create a ticket](https://github.com/phoenixvc/agentkit-forge/issues/new?title=Onboard+azure-project-template&labels=onboarding).

## Baton Integration

Baton is the shared task graph for cross-repo work. When the `baton` MCP server is available, agents should check for existing work with `task_check` at the start of meaningful tasks, create or claim visible work with `task_notify`/`log_agent_message`, update the task when significant new information becomes available, and log completion or blockers before handing off.
