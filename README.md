# Run ECS under EC2 instances using terraform

- deploy cluster with 2 instances using Autoscaling and Launch configuration
- cluster firewall runnning with opened port 32768-65535 TCP from source: lb-sg 
- set Application Load Balancer to manage traffic from the Internet to docker images in EC2s
- ALB with firewall (lb-sg) opened to the World on port HTTP and HTTPS
- apply Target Group to manage EC2s in cluster
- deploy service in cluster with Task Definition
- set Task Definition: docker image of website
- build container in softserve.json
- attach standard IAM Policy to cluster {var.iam_policy_arn}

## Setup:
`terraform apply`

## Clean up:
```sh
terraform plan -destroy -out destroy.plan
terraform apply destroy.plan
```