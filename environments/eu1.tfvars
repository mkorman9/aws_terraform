environment = "eu1"
profile     = "prd"
aws_region  = "eu-central-1"

instance_type     = "t2.micro"
min_instances     = 1
max_instances     = 1
desired_instances = 1

app_image             = "778189968080.dkr.ecr.eu-central-1.amazonaws.com/go-commons:latest"
app_min_instances     = 1
app_max_instances     = 1
app_desired_instances = 1
app_domain            = "eu.siurkiidziurki.online"
