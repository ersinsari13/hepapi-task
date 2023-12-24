pipeline {
    agent any
    environment {
        APP_NAME="petclinic-argocd"
        APP_REPO_NAME="hepapi/${APP_NAME}-app-prod"
    }
    stages {

        stage('Docker login') {
            docker login
        }

        stage('Package application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_PETCLINIC="${ECR_REGISTRY}/${APP_REPO_NAME}:ersin-petclinic-prod-v${MVN_VERSION}-b${BUILD_NUMBER}"
                }
            }
        }
        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh ". ./jenkins/build-prod-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-prod-docker-images-to-ecr.sh"
            }
        }
        stage('Deploy App on Kubernetes Cluster'){
            steps {
                echo 'Deploying App on Kubernetes Cluster'
                sh '. ./jenkins/deploy_app_on_prod_environment.sh'
            }
        }
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }

        success {
            mail bcc: '', body: 'Congrats !!! CICD Pipeline is successfull.', cc: '', from: '', replyTo: '', subject: 'Test Mail', to: 'sariiersinn13@gmail.com'
            }
    }
}