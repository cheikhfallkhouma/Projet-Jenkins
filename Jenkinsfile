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
        // Pas de DOCKERHUB_AUTH ici car récupéré via withCredentials
        // Idem pour MYSQL_ROOT_PASSWORD, MYSQL_USER, MYSQL_PASSWORD si besoin
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
                    sh '''
                        mvn clean test -B -V
                    '''
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
                    sh '''
                        mvn verify -Pintegration-tests
                    '''
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
                HOSTNAME_DEPLOY_STAGING = "52.91.199.18"
            }
            steps {
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

                            echo "📦 Copie du fichier docker-compose.yml vers le serveur"
                            sh "scp docker-compose.yml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yml"

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

                            echo "🚀 Lancement du déploiement Docker Compose"
                            sh """
                                ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} bash -c "'
                                    if ! command -v docker &> /dev/null; then
                                        curl -fsSL https://get.docker.com | sh
                                    fi

                                    if ! command -v docker-compose &> /dev/null; then
                                        sudo curl -L \\"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\\" -o /usr/local/bin/docker-compose
                                        sudo chmod +x /usr/local/bin/docker-compose
                                    fi

                                    sudo usermod -aG docker ubuntu
                                    newgrp docker || true

                                    cd /home/ubuntu
                                    echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

                                    sudo docker-compose pull
                                    sudo docker-compose down
                                    sudo docker-compose up -d
                                '"
                            """
                        }
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
            echo '❌ Échec de la pipeline!'
        }
    }
}
