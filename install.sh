# For installation docker and docker-compose on Ubuntu EC2 AWS 

sudo apt update -y
curl -fsSL https://get.docker.com -o install-docker.sh
sh install-docker.sh --dry-run
sudo sh install-docker.sh
sudo usermod -aG docker $(whoami)
newgrp docker
sudo apt  install docker-compose


# Docker-compose file for Jenkins
# docker-compose.yml
# This is a sample docker-compose file for Jenkins
# It uses the official Jenkins image and mounts the Docker socket
# to allow Jenkins to run Docker commands
# Sometimes, you may need to remove the version for docker-compose and chose an other version or not specify any version

version: '4'
services:
  jenkins:
    privileged: true
    user: root
    container_name: jenkins-launch
    image: jenkins/jenkins:2.490-jdk17
    restart: always
    ports:
      - 8080:8080
      - 50000:50000
    volumes:
      - /usr/bin/docker:/usr/bin/docker 
      - jenkins_launch:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock      
volumes:
 jenkins_launch:
