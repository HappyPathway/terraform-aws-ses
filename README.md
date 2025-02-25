# morpheus-workspace

Base repository for Morpheus workspace infrastructure modules

## Getting Started

1. Clone this repository:
```bash
git clone git@github.com:HappyPathway/morpheus-workspace.git
cd morpheus-workspace
```

2. Set up Python environment and install dependencies:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows use: .venv\Scripts\activate
pip install -r scripts/requirements.txt
```

3. Run the initialization script:
```bash
python scripts/init.py
```

This will:
- Verify Git SSH access to GitHub
- Create the workspace directory structure
- Clone or update all project repositories
- Set up repository configurations

For debugging, you can run:
```bash
python scripts/init.py --debug
```

## Repository Structure

This project consists of multiple repositories:

- terraform-aws-cluster: morpheus-workspace::terraform-aws-cluster
- terraform-aws-efs: morpheus-workspace::terraform-aws-efs
- terraform-aws-mq-cluster: morpheus-workspace::terraform-aws-mq-cluster
- terraform-aws-opensearch-cluster: morpheus-workspace::terraform-aws-opensearch-cluster
- terraform-aws-rds: morpheus-workspace::terraform-aws-rds
- terraform-aws-ses: morpheus-workspace::terraform-aws-ses

## Development Environment

This repository includes:
- VS Code workspace configuration
- GitHub Copilot settings
- Project-specific documentation and guidelines
- Python-based initialization tools

## Contributing

Please see the [CONTRIBUTING.md](.github/CONTRIBUTING.md) file for guidelines.