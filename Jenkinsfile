pipeline {
    agent none  // Cela signifie que ce pipeline n'a pas d'agent global, il faut définir un agent pour chaque stage

    stages {
        stage('Tests Unitaires') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'  // Utilisation de l'image Docker avec Maven et OpenJDK 17
                    args '-v $HOME/.m2:/root/.m2'  // Monte le répertoire Maven local pour garder un cache des dépendances
                }
            }
            steps {
                // Exécution de Maven pour nettoyer et installer les dépendances
                steps {
                        // Nettoyer le cache Maven et exécuter Maven clean install
                        sh 'rm -rf $HOME/.m2/repository/* && mvn clean install'
                }
            }
        }
    }

    post {
        success {
            // Message en cas de succès des tests
            echo '✅ Tests unitaires réussis.'
        }
        failure {
            // Message en cas d'échec des tests
            echo '❌ Les tests unitaires ont échoué.'
        }
    }
}

// }
