open_ip = ["0.0.0.0/0"]
project_name = "web"
environment = "test" # test / env / dev
availability_zones = ["eu-west-1a", "eu-west-1b"]
max_size = 3
min_size = 1
desired_capacity = 2
instance_type = "t3.micro"
ecs_ami = "ami-0b11be160d53889ae"
iam_policy_arn = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
"arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]