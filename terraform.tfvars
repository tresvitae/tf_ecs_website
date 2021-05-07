open_ip = ["0.0.0.0/0"]
project_name = "web_app"
environment = "test"
# The AMI to seed ECS instances with.
# Leave empty to use the latest Linux 2 ECS-optimized AMI by Amazon.
#aws_ecs_ami = ""
availability_zones = ["eu-west-1a", "eu-west-1b"]

# Maximum, minimum and desired number of instances in the ECS cluster.
max_size = 3
min_size = 1
desired_capacity = 2
instance_type = "t2.micro"
ecs_ami = "ami-0b11be160d53889ae"
