open_ip            = ["0.0.0.0/0"]
project_name       = "web"
availability_zones = ["eu-west-1a", "eu-west-1b"]
max_size           = 3
min_size           = 1
desired_capacity   = 2
instance_prod      = "t2.small" 
instance_test      = "t2.micro"
ecs_ami            = "ami-0b11be160d53889ae"
iam_policy_arn     = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
"arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
bucket             = "tf-state-softserve"
dynamodb_table     = "tf-locks"