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

# Service deployment

The following steps cover the deployment process for - https://github.com/mkorman9/kotlin-vertx

## Configure ECR registry

- Go to `ECR` and create a registry with the name equal to the name of the image
- Click `View Push Commands`, configure Docker locally and push the image
- Push kotlin-vertx image into the registry

## Create RDS database

- Go to `RDS`
- Create Postgres database
- Place it in the `*-vpc` network
- Do **NOT** enable Public Access
- Create a security group with an inbound rule allowing traffic to port `5432` from `0.0.0.0/0`

## Create secrets in Secrets Manager

- Go to `AWS Secrets Manager` and create new secret
- Choose `Other type of secret` and add all fields manually (for example username and password to RDS)
- You will be given the root ARN of the secret, such as `arn:aws:secretsmanager:eu-central-1:778189968080:secret:db-credentials-63edbZ`
- In order to select a specific field of the secret, use the following syntax `arn:aws:secretsmanager:eu-central-1:778189968080:secret:db-credentials-63edbZ:password::` (append field name, `password` in this example and two colons)

## Create ECS Task Definition

- Go to `ECS` and create new `EC2 Task Definition`
- Under `Task role` select `*-app-role`
- Under `Task execution role` select `*-task-execution-role`
- Requires compatibilities - `EC2`
- Specify total memory and CPU requirements, such as `1024 MB` and `1024` (1 vCPU)
- Add container and specify a path to the image previously uploaded to the ECR
- Memory limit - same as specified for task
- Part mapping - Container Port: `8080`, Host Port: `<LEAVE EMPTY>`
- Healthcheck - Command: `CMD-SHELL, curl -f http://localhost:8080/health || exit 1`
- CPU Units - same as specified for task
- Environment variables - all required for app to run, such as URL for RDS etc. (In order to retrieve a value from Secrets Manager, change `Value` to `ValueFrom` and use the syntax described in Secrets Manager section as an environment variable value)
- Log driver - `awslogs`
- Apply and finish creating task definition

## Create ECS Service

- Go to your ECS cluster and create new Service
- Launch type - `EC2`
- Task definition - previously created task definition
- Service type - `REPLICA`
- Number of tasks - at least `3` for production traffic
- Deployment type - `Rolling Update`
- Next
- Load Balancer - `Application Load Balancer`
- Under `Service IAM role` select `*-ecs-role`
- Under `Load balancer name` select `*-lb`
- Select a container and click `Add to load balancer`
- Under `Production listener port` select `80:HTTP`
- Under `Target group name` select `create new`
- Path pattern - `/api*`
- Health check path - `/health`
- Next
- Optionally configure auto scaling
- Create

Service should start immediately and bind to the load balancer. Logs should be available in `CloudWatch` tool.
