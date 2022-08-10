# Prerequisites

- Terraform installed
- aws-cli installed
- AWS Credentials set up

# Usage

Create infrastructure:
```
terraform apply -var environment=eu1 -var aws_region=eu-central-1 -var app_domain=app.example.com
```
