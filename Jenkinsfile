pipeline {

    agent {
        docker {
            image 'maven:3.9.9-amazoncorretto-8-al2023'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        PORT_EXPOSED = "80"
        IMAGE_NAME = 'paymybuddy'
        IMAGE_TAG = 'latest'
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
                    echo "🕐 Début des tests unitaires : ${new Date()}"
                    sh 'mvn clean test -B -V'
                    echo "✅ Fin des tests unitaires : ${new Date()}"
                }
            }
        }

        stage('Tests d’Intégration') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🧪 Début des tests d'intégration : ${new Date()}"
                    sh 'mvn verify -Pintegration-tests'
                    echo "✅ Fin des tests d'intégration : ${new Date()}"
                }
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
                withSonarQubeEnv('SonarCloud') {
                    echo '📊 Analyse SonarCloud...'
                    sh """
                        mvn verify sonar:sonar \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.organization=cheikhfallkhouma-1 \
                            -Dsonar.projectKey=cheikhfallkhouma_Projet-Jenkins
                    """
                }
            }
        }

        stage('Vérification Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Package') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn package -DskipTests'
                stash includes: 'target/paymybuddy.jar', name: 'built-jar'
            }
        }

        stage('Build Image and Push') {
            steps {
                unstash 'built-jar'  // 🔁 Restaurer le jar dans le contexte du build

                withCredentials([usernamePassword(
                    credentialsId: 'DOCKERHUB_AUTH',
                    usernameVariable: 'DOCKERHUB_AUTH',
                    passwordVariable: 'DOCKERHUB_AUTH_PSW'
                )]) {
                    sh '''
                        echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin
                        docker build -t ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG} .
                        docker push ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy in Staging') {
            environment {
                HOSTNAME_DEPLOY_STAGING = "54.174.238.234"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKERHUB_AUTH',
                            usernameVariable: 'DOCKERHUB_AUTH',
                            passwordVariable: 'DOCKERHUB_AUTH_PSW'
                        ),
                        string(credentialsId: 'DB_USER', variable: 'DB_USER'),
                        string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'),
                        string(credentialsId: 'DB_ROOT_PASSWORD', variable: 'DB_ROOT_PASSWORD')
                    ]) {
                        sh '''
                            [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

                            cp docker-compose.template.yml docker-compose.yml
                            sed -i "s|__DB_USER__|${DB_USER}|g" docker-compose.yml
                            sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" docker-compose.yml
                            sed -i "s|__DB_ROOT_PASSWORD__|${DB_ROOT_PASSWORD}|g" docker-compose.yml
                            sed -i "s|__DOCKER_IMAGE__|${DOCKERHUB_AUTH}/paymybuddy:latest|g" docker-compose.yml

                            scp docker-compose.yml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yml

                            ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                                if ! command -v docker &> /dev/null; then
                                    curl -fsSL https://get.docker.com | sh
                                fi
                                sudo systemctl start docker || true
                                sudo usermod -aG docker ubuntu

                                echo 'Connexion DockerHub'
                                echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

                                cd /home/ubuntu
                                sudo apt install docker-compose -y
                                docker-compose pull
                                docker-compose down
                                docker-compose up -d

                                docker ps
                            "
                        '''
                    }
                }
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
}




// pipeline {
//     agent {
//         docker {
//             image 'maven:3.9.6-eclipse-temurin-17'
//             args '-v /var/run/docker.sock:/var/run/docker.sock'
//         }
//     }

//     options {
//         buildDiscarder(logRotator(numToKeepStr: '10'))
//         skipDefaultCheckout()
//         timestamps()
//     }

//     environment {
//         SONAR_TOKEN = credentials('SONAR_TOKEN')
//         IMAGE_NAME = 'paymybuddy'
//         IMAGE_TAG = 'latest'
//         PORT_EXPOSED = "80"
//     }

//     stages {

//         stage('Tests Unitaires') {
//             agent {
//                 docker {
//                     image 'maven:3.9.6-eclipse-temurin-17'
//                     args '-v $HOME/.m2:/root/.m2'
//                 }
//             }
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     sh 'mvn clean test -B -V'
//                 }
//             }
//         }

//         stage('Tests d’Intégration') {
//             agent {
//                 docker {
//                     image 'maven:3.9.6-eclipse-temurin-17'
//                     args '-v $HOME/.m2:/root/.m2'
//                 }
//             }
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     sh 'mvn verify -Pintegration-tests'
//                 }
//             }
//         }

//         stage('Analyse SonarCloud') {
//             agent {
//                 docker {
//                     image 'maven:3.9.6-eclipse-temurin-17'
//                     args '-v $HOME/.m2:/root/.m2'
//                 }
//             }
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     withSonarQubeEnv('SonarCloud') {
//                         sh """
//                             mvn verify sonar:sonar \
//                                 -Dsonar.login=${SONAR_TOKEN} \
//                                 -Dsonar.host.url=https://sonarcloud.io \
//                                 -Dsonar.organization=cheikhfallkhouma-1 \
//                                 -Dsonar.projectKey=cheikhfallkhouma_Projet-Jenkins
//                         """
//                     }
//                 }
//             }
//         }

//         stage('Vérification Quality Gate') {
//             steps {
//                 timeout(time: 1, unit: 'MINUTES') {
//                     waitForQualityGate abortPipeline: true
//                 }
//             }
//         }

//         stage('Package') {
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     sh 'mvn package -DskipTests'
//                 }
//             }
//         }

//         stage('Build & Push Docker Image') {
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     withCredentials([usernamePassword(
//                         credentialsId: 'DOCKERHUB_AUTH',
//                         usernameVariable: 'DOCKERHUB_AUTH',
//                         passwordVariable: 'DOCKERHUB_AUTH_PSW'
//                     )]) {
//                         sh '''
//                             echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin
//                             docker build -t ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG} .
//                             docker push ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
//                         '''
//                     }
//                 }
//             }
//         }

//         stage('Deploy in Staging') {
//             environment {
//                 HOSTNAME_DEPLOY_STAGING = "23.22.211.169"
//             }
//             steps {
//                 wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
//                     sshagent(credentials: ['SSH_AUTH_SERVER']) {
//                         withCredentials([
//                             usernamePassword(credentialsId: 'DOCKERHUB_AUTH', usernameVariable: 'DOCKERHUB_AUTH', passwordVariable: 'DOCKERHUB_AUTH_PSW'),
//                             string(credentialsId: 'DB_USER', variable: 'DB_USER'),
//                             string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'),
//                             string(credentialsId: 'DB_ROOT_PASSWORD', variable: 'DB_ROOT_PASSWORD')
//                         ]) {
//                             sh '''
//                             set +x

//                             mkdir -p ~/.ssh && chmod 700 ~/.ssh
//                             ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

//                             TMP_DOCKER_COMPOSE="/tmp/docker-compose.staging.yml"
//                             cp docker-compose.template.yml $TMP_DOCKER_COMPOSE

//                             sed -i "s|__DB_USER__|${DB_USER}|g" $TMP_DOCKER_COMPOSE
//                             sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" $TMP_DOCKER_COMPOSE
//                             sed -i "s|__DB_ROOT_PASSWORD__|${DB_ROOT_PASSWORD}|g" $TMP_DOCKER_COMPOSE
//                             sed -i "s|__DOCKER_IMAGE__|${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}|g" $TMP_DOCKER_COMPOSE

//                             docker-compose -f $TMP_DOCKER_COMPOSE config

//                             scp $TMP_DOCKER_COMPOSE ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.staging.yml

//                             ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
//                                 curl -fsSL https://get.docker.com | sh || true
//                                 sudo systemctl start docker || true

//                                 echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

//                                 cd /home/ubuntu
//                                 sudo apt update && sudo apt install -y docker-compose
//                                 docker-compose -f docker-compose.staging.yml pull
//                                 docker-compose -f docker-compose.staging.yml down || true
//                                 docker-compose -f docker-compose.staging.yml up -d
//                             "
//                             '''
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     post {
//         success {
//             echo '✅ Pipeline terminée avec succès.'
//         }
//         failure {
//             echo '❌ Échec de la pipeline.'
//         }
//     }
// }
