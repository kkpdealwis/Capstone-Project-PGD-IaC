#!/bin/bash

# install docker in ec2 instance
sudo apt-get update
sudo wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
sudo apt-get update; sudo apt-get install -y java-17-amazon-corretto-jdk
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y fontconfig fonts-dejavu
sudo apt-get install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
 $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install  -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker jenkins

#Install apache maven

#wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
#tar -xvf apache-maven-3.9.9-bin.tar.gz
#mv apache-maven-3.9.9 /opt/

# Install pipx
sudo apt-get install -y pipx

#Install ansible using pipx
#pipx install ansible
#pipx ensurepath

# Edit the /etc/profile file with maven bin path
#sudo cat << EOF >> /etc/profile
#JAVA_HOME="/opt/apache-maven-3.9.9"
#PATH="\$JAVA_HOME/bin:\$PATH"
#ANSIBLE_HOME="/root/.local/share/pipx/venvs/ansible/"
#PATH="\$ANSIBLE_HOME/bin:\$PATH"
#export PATH
#EOF

# reload the /etc/profile
#sudo cat << EOF >> /root/.bashrc
#source /etc/profile
#sudo cat << EOF >> /home/ubuntu/.bashrc
#source /etc/profile
#EOF


