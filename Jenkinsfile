pipeline {
    agent none

    stages {
        stage('Tests Unitaires') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'rm -rf $HOME/.m2/repository/* && mvn clean install'
            }
        }
    }

    post {
        success {
            echo '✅ Tests unitaires réussis.'
        }
        failure {
            echo '❌ Les tests unitaires ont échoué.'
        }
    }
}
