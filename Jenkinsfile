pipeline {
    agent none  // On déclare "none" ici car chaque stage utilise son propre agent

    stages {
        stage('Tests Unitaires') {
            agent { docker { image 'maven:3.9.6-eclipse-temurin-17'
                                args '-v /var/run/docker.sock:/var/run/docker.sock, -v /root/.m2:/root/.m2' } }
                                
             } }
            steps {
                sh 'mvn test'
            }
        }
    
