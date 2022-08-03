# Prerequisites

- Terraform installed
- aws-cli installed
- AWS Credentials set up

# Usage

Create infrastructure:
```
terraform apply -var environment=eu1 -var aws_region=eu-central-1
```

Deploy service on top of that:
```
cd service
terraform apply -var environment=eu1 -var aws_region=eu-central-1
```
