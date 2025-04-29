// pipeline {
//     agent none

//     stages {
//         stage('Tests Unitaires') {
//             agent {
//                 docker {
//                     image 'maven:3.9.6-eclipse-temurin-17'
//                     args '-v $HOME/.m2:/root/.m2'  // Pour cacher localement le repo maven
//                 }
//             }
//             steps {
//                 sh 'mvn clean test'
//             }
//         }
//     }

//     post {
//         success {
//             echo '✅ Tests unitaires réussis.'
//         }
//         failure {
//             echo '❌ Les tests unitaires ont échoué.'
//         }
//     }
// }

pipeline {
    agent any

    stages {
        stage('Tests Unitaires') {
            steps {
                sh 'mvn test'
            }
        }

        
    }
}


