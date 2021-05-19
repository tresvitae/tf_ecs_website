#!/bin/bash

wget -O- https://apt.corretto.aws/corretto.key | apt-key add - 
add-apt-repository 'deb https://apt.corretto.aws stable main'
apt-get update
apt-get install -y java-11-amazon-corretto-jdk
apt-get install -y nginx
#2CPU 4RAM
wget https://download.jetbrains.com/teamcity/TeamCity-2020.2.4.tar.gz
tar -xzf TeamCity-2020.2.4.tar.gz 
./TeamCity/bin/runAll.sh start

cat << EOF > /etc/nginx/sites-available/teamcity
server {

    listen       80;
    server_name _;

    proxy_read_timeout     1200;
    proxy_connect_timeout  240;
    client_max_body_size   0;

    location / {

        proxy_pass          http://localhost:8111/;
        proxy_http_version  1.1;
        proxy_set_header    X-Forwarded-For \$remote_addr;
        proxy_set_header    Host \$server_name:\$server_port;
        proxy_set_header    Upgrade \$http_upgrade;

    }
}
EOF

ln -s /etc/nginx/sites-available/teamcity /etc/nginx/sites-enabled/teamcity
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default
service nginx restart
# Set welcome message
cat << EOF >> /etc/update-motd.d/00-header
printf "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
printf "\nlocalhost:8111\n"
printf "TEAMCITY TOKEN: cat /TeamCity/logs/teamcity-server.log | grep 'Super user authentication token'\n"
printf "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
EOF

#Install terraform
apt-get update
apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y terraform


# Install AWS CLI
apt-get update
apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
