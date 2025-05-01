pipeline {
    agent none

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN')
    }

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
                        echo "🚀 Lancement de mvn clean test..."
                        mvn clean test -B -V
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

    
stage('Analyse SonarCloud') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                echo '📊 Lancement de l’analyse SonarCloud...'
                sh """
                    mvn verify sonar:sonar \
                        -Dsonar.login=${SONAR_TOKEN}
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline terminée avec succès.'
        }
        failure {
            echo '❌ Échec de la pipeline.'
        }
    }
