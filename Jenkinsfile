pipeline {
    agent any

    tools {
        maven 'Maven-3.9.16'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn -B test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([
                        string(
                            credentialsId: 'sonar-token',
                            variable: 'SONAR_TOKEN'
                        )
                    ]) {
                        sh '''
                            mvn -B sonar:sonar \
                              -Dsonar.projectKey=habit-tracker \
                              -Dsonar.host.url=http://host.docker.internal:9000 \
                              -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    sh """
                        docker build \
                          -t srkishore/habit-tracker:${IMAGE_TAG} \
                          .
                    """
                }
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                            -u "$DOCKER_USERNAME" \
                            --password-stdin

                        docker push srkishore/habit-tracker:${IMAGE_TAG}

                        docker logout
                    '''
                }
            }
        }

        stage('Update GitOps') {
            steps {
                script {

                    dir('gitops') {

                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: '*/main']],
                            userRemoteConfigs: [[
                                url: 'https://github.com/kishore-stack/HabitApp-GitOps.git',
                                credentialsId: 'github-gitops'
                            ]]
                        ])

                        sh """
                            sed -i 's/^  tag: .*/  tag: "${IMAGE_TAG}"/' helm/values.yaml
                        """

                        sh 'git diff -- helm/values.yaml'

                        sh """
                            git config user.name "Jenkins"
                            git config user.email "jenkins@localhost"

                            git add helm/values.yaml

                            git commit -m "Update Habit Tracker image to ${IMAGE_TAG}" || echo "No changes to commit"
                        """

                        withCredentials([
                            usernamePassword(
                                credentialsId: 'github-gitops',
                                usernameVariable: 'GIT_USERNAME',
                                passwordVariable: 'GIT_PASSWORD'
                            )
                        ]) {

                            sh '''
                                cat > askpass.sh <<'EOF'
#!/bin/sh
case "$1" in
    *Username*) echo "$GIT_USERNAME" ;;
    *Password*) echo "$GIT_PASSWORD" ;;
esac
EOF

                                chmod 700 askpass.sh

                                GIT_ASKPASS="$PWD/askpass.sh" \
                                GIT_TERMINAL_PROMPT=0 \
                                git push origin main

                                rm -f askpass.sh
                            '''
                        }
                    }
                }
            }
        }

    }
}