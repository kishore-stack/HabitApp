pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify') {
            steps {
                sh 'echo "Jenkins checkout successful"'
                sh 'git rev-parse --short HEAD'
                sh 'java -version'
                sh 'mvn -version'
            }
        }
    }
}