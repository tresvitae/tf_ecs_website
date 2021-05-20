# Instalation of TeamCity CI using EC2  

Use startup.sh file in User Data
Select min 2CPU and 4 GiB memory instance type
Open port 8111 in Security Group

- Super user authentication token can be found in `cat /TeamCity/logs/teamcity-server.log | grep 'Super user authentication token'`  
- AWS CLI needs to be configured `aws configure`