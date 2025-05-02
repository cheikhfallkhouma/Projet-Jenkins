    pipeline {
        agent {
            docker {
                image 'maven:3.8.6-openjdk-17'
                label 'docker-java'
                args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.m2:/root/.m2'
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
                        echo "🕐 Début de la compilation : ${new Date()}"
                        sh 'mvn clean test -B -V'
                        echo "✅ Fin de la compilation : ${new Date()}"
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
                        echo '📊 Lancement de l’analyse SonarCloud...'
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

            stage('Build Image and Push Image') {
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
