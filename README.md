# VS Code Server JFrog POC

This project demonstrates a DevOps CI/CD workflow using:

- GitHub
- Harness
- Python
- Pytest
- Coverage
- Ruff
- Docker
- JFrog Artifactory
- Azure Container Registry
- Azure Container Apps
- VS Code Server

## Workflow

GitHub
→ Harness CI/CD
→ Test
→ Coverage
→ Ruff
→ Docker Build
→ JFrog Python Packages
→ Azure Container Registry
→ Azure Container Apps
→ VS Code Server

## Python packages

The application uses:

- `requests` from public PyPI through JFrog
- `poc-hello-package` from the private JFrog repository

## Container

VS Code Server runs on port 8080.