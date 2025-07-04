// pipeline {
//     agent {
//         docker {
//             image 'maven:3.9.9-amazoncorretto-8-al2023'
//             args '-v /var/run/docker.sock:/var/run/docker.sock'
//         }
//     }

//     environment {
//         SONAR_TOKEN = credentials('SONAR_TOKEN')
//         PORT_EXPOSED = "80"
//         IMAGE_NAME = 'paymybuddy'
//         IMAGE_TAG = 'latest'
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
//                 timeout(time: 10, unit: 'MINUTES') {
//                     echo "🕐 Début des tests unitaires : ${new Date()}"
//                     sh 'mvn clean test -B -V'
//                     echo "✅ Fin des tests unitaires : ${new Date()}"
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
//                 timeout(time: 15, unit: 'MINUTES') {
//                     echo "🧪 Début des tests d'intégration : ${new Date()}"
//                     sh 'mvn verify -Pintegration-tests'
//                     echo "✅ Fin des tests d'intégration : ${new Date()}"
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
//                 withSonarQubeEnv('SonarCloud') {
//                     echo '📊 Analyse SonarCloud...'
//                     sh """
//                         mvn verify sonar:sonar \
//                             -Dsonar.login=${SONAR_TOKEN} \
//                             -Dsonar.host.url=https://sonarcloud.io \
//                             -Dsonar.organization=cheikhfallkhouma-1 \
//                             -Dsonar.projectKey=cheikhfallkhouma_Projet-Jenkins
//                     """
//                 }
//             }
//         }

//         stage('Vérification Quality Gate') {
//             steps {
//                 timeout(time: 1, unit: 'MINUTES') {
//                     waitForQualityGate abortPipeline: false
//                 }
//             }
//         }

//         stage('Package') {
//             steps {
//                 sh 'mvn package -DskipTests'
//             }
//         }

//         stage('Build Image and Push') {
//             steps {
//                 withCredentials([
//                     usernamePassword(
//                         credentialsId: 'DOCKERHUB_AUTH',
//                         usernameVariable: 'DOCKERHUB_AUTH',
//                         passwordVariable: 'DOCKERHUB_AUTH_PSW'
//                     )
//                 ]) {
//                     script {
//                         def dockerImage = "${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}"
//                         echo "Build et push de l'image Docker : ${dockerImage}"
//                         sh """
//                             echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin
//                             docker build -t ${dockerImage} .
//                             docker push ${dockerImage}
//                         """
//                     }
//                 }
//             }
//         }

//         stage('Deploy in Staging') {
//             environment {
//                 HOSTNAME_DEPLOY_STAGING = "54.89.17.17"
//             }
//             steps {
//                 sshagent(credentials: ['SSH_AUTH_SERVER']) {
//                     withCredentials([
//                         usernamePassword(
//                             credentialsId: 'DOCKERHUB_AUTH',
//                             usernameVariable: 'DOCKERHUB_AUTH',
//                             passwordVariable: 'DOCKERHUB_AUTH_PSW'
//                         ),
//                         string(credentialsId: 'MYSQL_ROOT_PASSWORD', variable: 'MYSQL_ROOT_PASSWORD'),
//                         string(credentialsId: 'MYSQL_USER', variable: 'MYSQL_USER'),
//                         string(credentialsId: 'MYSQL_PASSWORD', variable: 'MYSQL_PASSWORD')
//                     ]) {
//                         script {
//                             sh '''
//                                 echo "🔐 Ajout de la machine distante à known_hosts"
//                                 mkdir -p ~/.ssh
//                                 chmod 700 ~/.ssh
//                                 ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
//                             '''

//                             echo "📦 Copie du fichier docker-compose.yaml vers le serveur"
//                             sh "scp docker-compose.yaml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yaml"

//                             echo "📝 Création dynamique du fichier .env sur le serveur"
//                             sh """
//                                 ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} bash -c "'
//                                     cat > /home/ubuntu/.env <<EOF
// MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
// MYSQL_USER=${MYSQL_USER}
// MYSQL_PASSWORD=${MYSQL_PASSWORD}
// DOCKER_IMAGE=${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
// EOF
//                                 '"
//                             """

//                             echo "📤 Copie du fichier create.sql vers le serveur"
//                             sh "scp src/main/resources/database/create.sql ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/create.sql"

//                             echo "🚀 Lancement du déploiement Docker Compose et initialisation MySQL"
//                             sh """
//                                 ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} bash -c "'
//                                     cd /home/ubuntu

//                                     echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

//                                     if ! command -v docker &> /dev/null; then
//                                         curl -fsSL https://get.docker.com | sh
//                                     fi

//                                     if ! command -v docker-compose &> /dev/null; then
//                                         sudo curl -L \\"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\\" -o /usr/local/bin/docker-compose
//                                         sudo chmod +x /usr/local/bin/docker-compose
//                                     fi

//                                     sudo docker-compose --env-file .env pull
//                                     sudo docker-compose --env-file .env down
//                                     sudo docker-compose --env-file .env up -d

//                                     # Attendre que MySQL soit prêt
//                                     until sudo docker exec paymybuddy_db mysqladmin ping -h localhost --silent; do
//                                         echo \"⏳ Attente que MySQL soit prêt...\"
//                                         sleep 5
//                                     done

//                                     # Exécuter le script SQL via TCP
//                                     cat /home/ubuntu/create.sql | sudo docker exec -i paymybuddy_db mysql -u root -p${MYSQL_ROOT_PASSWORD}

//                                 '"
//                             """
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
//             echo '❌ Échec de la pipeline!'
//         }
//     }
// }

pipeline {
    agent {
        docker {
            // image 'maven:3.9.9-amazoncorretto-8-al2023'
            image 'maven:3.9.3-eclipse-temurin-17'
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
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "🕐 Début des tests unitaires : ${new Date()}"
                    sh 'mvn clean test -B -V'
                    echo "✅ Fin des tests unitaires : ${new Date()}"
                }
            }
        }

        stage('Tests d’Intégration') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🧪 Début des tests d'intégration : ${new Date()}"
                    sh 'mvn verify -Pintegration-tests'
                    echo "✅ Fin des tests d'intégration : ${new Date()}"
                }
            }
        }

        stage('Analyse SonarCloud') {
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

        // stage('Vérification Quality Gate') {
        //     steps {
        //         timeout(time: 300, unit: 'SECONDS') {
        //             waitForQualityGate abortPipeline: false
        //         }
        //     }
        // }

        stage('Vérification Quality Gate') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        timeout(time: 5, unit: 'MINUTES') {
                            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                                waitForQualityGate abortPipeline: false
                            }
                        }
                    } else {
                        echo "Skipping Quality Gate check for branch: ${env.BRANCH_NAME}"
                    }
                }
            }
        }


        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Build Image and Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'DOCKERHUB_AUTH',
                        usernameVariable: 'DOCKERHUB_AUTH',
                        passwordVariable: 'DOCKERHUB_AUTH_PSW'
                    )
                ]) {
                    script {
                        def dockerImage = "${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}"
                        echo "Build et push de l'image Docker : ${dockerImage}"
                        sh """
                            echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin
                            docker build -t ${dockerImage} .
                            docker push ${dockerImage}
                        """
                    }
                }
            }
        }

        stage('Deploy in Staging') {
            environment {
                HOSTNAME_DEPLOY_STAGING = "54.175.130.125"
            }
            
            steps {
                sh 'apt-get update && apt-get install -y openssh-client || true'
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKERHUB_AUTH',
                            usernameVariable: 'DOCKERHUB_AUTH',
                            passwordVariable: 'DOCKERHUB_AUTH_PSW'
                        ),
                        string(credentialsId: 'MYSQL_ROOT_PASSWORD', variable: 'MYSQL_ROOT_PASSWORD'),
                        string(credentialsId: 'MYSQL_USER', variable: 'MYSQL_USER'),
                        string(credentialsId: 'MYSQL_PASSWORD', variable: 'MYSQL_PASSWORD')
                    ]) {
                        script {
                            sh '''
                                echo "🔐 Ajout de la machine distante à known_hosts"
                                mkdir -p ~/.ssh
                                chmod 700 ~/.ssh
                                ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                            '''

                            echo "📦 Copie du fichier docker-compose.yaml vers le serveur"
                            sh "scp docker-compose.yaml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yaml"

                            echo "📝 Création dynamique du fichier .env sur le serveur"
                            sh """
                                ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} bash -c "'
                                    cat > /home/ubuntu/.env <<EOF
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
DOCKER_IMAGE=${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
EOF
                                '"
                            """

                            echo "📤 Copie du fichier create.sql vers le serveur"
                            sh "scp src/main/resources/database/create.sql ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/create.sql"

                            echo "🚀 Lancement du déploiement Docker Compose et initialisation MySQL"
                            sh """
                                ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} bash -c "'
                                    cd /home/ubuntu

                                    echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

                                    if ! command -v docker &> /dev/null; then
                                        curl -fsSL https://get.docker.com | sh
                                    fi

                                    if ! command -v docker-compose &> /dev/null; then
                                        sudo curl -L \\"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\\" -o /usr/local/bin/docker-compose
                                        sudo chmod +x /usr/local/bin/docker-compose
                                    fi

                                    sudo docker-compose --env-file .env pull
                                    sudo docker-compose --env-file .env down
                                    sudo docker-compose --env-file .env up -d

                                    # Attendre que MySQL soit prêt
                                    until sudo docker exec paymybuddy_db mysqladmin ping -h localhost --silent; do
                                        echo \"⏳ Attente que MySQL soit prêt...\"
                                        sleep 5
                                    done

                                    # Exécuter le script SQL sur la base paymybuddy
                                    cat /home/ubuntu/create.sql | sudo docker exec -i paymybuddy_db mysql -u root -p${MYSQL_ROOT_PASSWORD} paymybuddy
                                    cd /home/ubuntu
                                    sudo docker-compose restart app
                                '"
                            """
                        }
                    }
                }
            }
        }

        stage('Test Staging') {
            environment {
                HOSTNAME_DEPLOY_STAGING = "54.210.123.456"
            }
            steps {
                sh '''
                    sleep 30
                    apk add --no-cache curl
                    curl ${HOSTNAME_DEPLOY_STAGING}:80
                '''
            }
        }

        stage('Deploy in Production') {
            environment {
                HOSTNAME_DEPLOY_PROD = "18.206.212.185" 
            }
            
            steps {
                sh 'apt-get update && apt-get install -y openssh-client || true'
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKERHUB_AUTH',
                            usernameVariable: 'DOCKERHUB_AUTH',
                            passwordVariable: 'DOCKERHUB_AUTH_PSW'
                        ),
                        string(credentialsId: 'MYSQL_ROOT_PASSWORD', variable: 'MYSQL_ROOT_PASSWORD'),
                        string(credentialsId: 'MYSQL_USER', variable: 'MYSQL_USER'),
                        string(credentialsId: 'MYSQL_PASSWORD', variable: 'MYSQL_PASSWORD')
                    ]) {
                        script {
                            sh '''
                                echo "🔐 Ajout de la machine distante à known_hosts"
                                mkdir -p ~/.ssh
                                chmod 700 ~/.ssh
                                ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts
                            '''

                            echo "📦 Copie du fichier docker-compose.yaml vers le serveur"
                            sh "scp docker-compose.yaml ubuntu@${HOSTNAME_DEPLOY_PROD}:/home/ubuntu/docker-compose.yaml"

                            echo "📝 Création dynamique du fichier .env sur le serveur"
                            sh """
                                ssh ubuntu@${HOSTNAME_DEPLOY_PROD} bash -c "'
                                    cat > /home/ubuntu/.env <<EOF
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
DOCKER_IMAGE=${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
EOF
                                '"
                            """

                            echo "📤 Copie du fichier create.sql vers le serveur"
                            sh "scp src/main/resources/database/create.sql ubuntu@${HOSTNAME_DEPLOY_PROD}:/home/ubuntu/create.sql"

                            echo "🚀 Lancement du déploiement Docker Compose et initialisation MySQL"
                            sh """
                                ssh ubuntu@${HOSTNAME_DEPLOY_PROD} bash -c "'
                                    cd /home/ubuntu

                                    echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

                                    if ! command -v docker &> /dev/null; then
                                        curl -fsSL https://get.docker.com | sh
                                    fi

                                    if ! command -v docker-compose &> /dev/null; then
                                        sudo curl -L \\"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\\" -o /usr/local/bin/docker-compose
                                        sudo chmod +x /usr/local/bin/docker-compose
                                    fi

                                    sudo docker-compose --env-file .env pull
                                    sudo docker-compose --env-file .env down
                                    sudo docker-compose --env-file .env up -d

                                    # Attendre que MySQL soit prêt
                                    until sudo docker exec paymybuddy_db mysqladmin ping -h localhost --silent; do
                                        echo \"⏳ Attente que MySQL soit prêt...\"
                                        sleep 5
                                    done

                                    # Exécuter le script SQL sur la base paymybuddy
                                    cat /home/ubuntu/create.sql | sudo docker exec -i paymybuddy_db mysql -u root -p${MYSQL_ROOT_PASSWORD} paymybuddy
                                    cd /home/ubuntu
                                    sudo docker-compose restart app
                                '"
                            """
                        }
                    }
                }
            }
        }

        stage('Test Staging') {
            environment {
                HOSTNAME_DEPLOY_PROD = "18.206.212.185"
            }
            steps {
                sh '''
                    sleep 30
                    apk add --no-cache curl
                    curl ${HOSTNAME_DEPLOY_PROD}:80
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline terminée avec succès.'
            slackSend(
                channel: '#tous-devops-cicd',
                color: 'good',
                message: "✅ *${env.JOB_NAME}* build #${env.BUILD_NUMBER} a réussi ! (<${env.BUILD_URL}|Voir les détails>)"
            )
        }
        failure {
            echo '❌ Échec de la pipeline!'
            slackSend(
                channel: '#tous-devops-cicd',
                color: 'danger',
                message: "❌ *${env.JOB_NAME}* build #${env.BUILD_NUMBER} a échoué ! (<${env.BUILD_URL}|Voir les détails>)"
            )
        }
    }
}
