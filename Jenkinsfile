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
                timeout(time: 10, unit: 'MINUTES') {
                    echo "🕐 Début de la compilation : ${new Date()}"
                    sh '''
                        echo "🚀 Lancement de mvn clean install..."
                        mvn clean install -B -V
                    '''
                    echo "✅ Fin de la compilation : ${new Date()}"
                }
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
