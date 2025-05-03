pipeline {
    
    agent {
        docker {
            image 'maven:3.9.3-eclipse-temurin-17'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        PORT_EXPOSED = "8080"
        IMAGE_NAME = 'paymybuddy'
        IMAGE_TAG = 'lastest'
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
                        echo "🚀 Lancement des tests d’intégration..."
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
                    echo '📊 Lancement de l’analyse SonarCloud...'
                    sh """
                        mvn verify sonar:sonar \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.organization=cheikhfallkhouma-1\
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

        stage('Build Image and push image') {
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

       
       stage('Deploy in staging') {
    environment {
        HOSTNAME_DEPLOY_STAGING = "3.84.110.84"
    }
    steps {
        sshagent(credentials: ['SSH_AUTH_SERVER']) {
            withCredentials([
                string(credentialsId: 'DB_USER', variable: 'DB_USER'),
                string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'),
                string(credentialsId: 'DB_ROOT_PASSWORD', variable: 'DB_ROOT_PASSWORD'),
                usernamePassword(
                    credentialsId: 'DOCKERHUB_AUTH',
                    usernameVariable: 'DOCKERHUB_AUTH',
                    passwordVariable: 'DOCKERHUB_AUTH_PSW'
                )
            ]) {
                sh '''
                    # S'assurer que le dossier .ssh existe
                    [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                    ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts

                    # Vérification si Docker est installé, si ce n'est pas le cas, installation
                    ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                        if ! command -v docker &> /dev/null; then
                            echo 'Docker non installé, installation via script officiel...'
                            curl -fsSL https://get.docker.com | sh
                        fi

                        # Démarrer Docker si nécessaire
                        if ! pgrep dockerd > /dev/null; then
                            echo 'Démarrage du daemon Docker...'
                            sudo systemctl start docker
                        fi

                        # Ajouter l'utilisateur ubuntu au groupe docker
                        sudo usermod -aG docker ubuntu
                    "

                    # Copier le fichier docker-compose.yml dans le répertoire de staging
                    scp docker-compose.yml ubuntu@${HOSTNAME_DEPLOY_STAGING}:/home/ubuntu/docker-compose.yml

                    # Lancer les services de base de données via docker-compose
                    ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                        cd /home/ubuntu &&
                        docker compose -f docker-compose.yml up -d
                    "

                    # Affichage de l'image avant de la récupérer
                    echo "Image to pull: ${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}"

                    # Commandes Docker à exécuter à distance
                    ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                        docker login -u '${DOCKERHUB_AUTH}' -p '${DOCKERHUB_AUTH_PSW}' &&
                        docker pull '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}' &&
                        docker rm -f paymaybuddywebapp || echo 'app does not exist' &&
                        docker run -d -p 80:5000 -e PORT=5000 --name paymaybuddywebapp '${DOCKERHUB_AUTH}/${IMAGE_NAME}:${IMAGE_TAG}'
                        sleep 3 &&
                        docker ps -a --filter name=paymaybuddywebapp &&
                        docker logs paymaybuddywebapp
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
