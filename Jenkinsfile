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
                        )
                    ]) {
                        sh '''
                            [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                            ssh-keyscan -t rsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

                            # Installer docker-compose si non installé
                            ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                                if ! command -v docker-compose &> /dev/null; then
                                    sudo curl -L 'https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose;
                                    sudo chmod +x /usr/local/bin/docker-compose;
                                fi

                                # Ajouter l'utilisateur ubuntu au groupe docker pour éviter sudo
                                sudo usermod -aG docker ubuntu

                                # Copier docker-compose.yml sur le serveur
                                scp docker-compose.yml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yml

                                # Connexion et déploiement
                                ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                                    if ! command -v docker &> /dev/null; then
                                        curl -fsSL https://get.docker.com | sh
                                    fi
                                    sudo systemctl start docker || true
                                    sudo usermod -aG docker ubuntu

                                    echo 'Login DockerHub et mise à jour de l\'image'
                                    echo '${DOCKERHUB_AUTH_PSW}' | docker login -u '${DOCKERHUB_AUTH}' --password-stdin

                                    cd /home/ubuntu
                                    docker-compose pull
                                    docker-compose down
                                    docker-compose up -d

                                    docker ps
                                "
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