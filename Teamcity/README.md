# Instalation of TeamCity CI using EC2  

Use startup.sh file in User Data
Select min 2CPU and 4 GiB memory instance type
Open port 8111 in Security Group

- Super user authentication token can be found in `cat /TeamCity/logs/teamcity-server.log | grep 'Super user authentication token'`  
- AWS CLI needs to be configured `aws configure`

Rolling update pipeline example:

1. `terraform init`
2. `terraform plan`
3. `jsonlint-php softserve.json`
4. `terraform workspace select prod`
5. `terraform apply -auto-approve`