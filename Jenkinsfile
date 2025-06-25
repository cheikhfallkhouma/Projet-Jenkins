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
                            -Dsonar.organization=xxxx-1 \
                            -Dsonar.projectKey=xxxxxx-Jenkins
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
                        sh '''
                            echo '⚙️ Génération de docker-compose.yml avec secrets'
                            export DOCKER_IMAGE=${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}
                            export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
                            export MYSQL_USER=${MYSQL_USER}
                            export MYSQL_PASSWORD=${MYSQL_PASSWORD}

                            envsubst < docker-compose.template.yml > docker-compose.yml

                            echo '📦 Envoi sur le serveur EC2'
                            ssh-keyscan -H ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                            scp docker-compose.yml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yml

                            echo '🚀 Déploiement à distance via SSH'
                            ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} '
                                if ! command -v docker &> /dev/null; then
                                    curl -fsSL https://get.docker.com | sh
                                fi

                                if ! command -v docker-compose &> /dev/null; then
                                    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                                    sudo chmod +x /usr/local/bin/docker-compose
                                fi

                                echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "${DOCKERHUB_AUTH}" --password-stdin

                                cd /home/ubuntu
                                docker-compose pull
                                docker-compose down
                                docker-compose up -d
                                docker ps
                            '
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
