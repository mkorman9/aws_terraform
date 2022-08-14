# Prerequisites

- Terraform installed
- aws-cli installed
- AWS Credentials set up

# Usage

Create infrastructure:
```
terraform apply -var environment=eu1 -var aws_region=eu-central-1 -var app_domain=app.example.com
```

# (Hint) Deploy new version of service

Install `ecs-deploy` (https://github.com/fabfuel/ecs-deploy)
```
pip install ecs-deploy
```

Or use Docker image
```
docker run fabfuel/ecs-deploy:1.10.2
```

Deploy container version `0.1.0-SNAPSHOT` of `eu1-app` service on cluster `eu1-cluster`
```
ecs deploy eu1-cluster eu1-app --tag 0.1.0-SNAPSHOT
```
