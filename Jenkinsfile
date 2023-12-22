pipeline {
    agent any
    environment {
        APP_NAME="petclinic"
        APP_REPO_NAME="hepapi/${APP_NAME}-app-prod"
        AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR="${APP_NAME}-prod-${BUILD_NUMBER}.key"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
        ANSIBLE_HOST_KEY_CHECKING="False"
    }
    stages {
        stage('Check S3 Bucket') {
            steps {
                script {
                    try {
                        // AWS CLI ile varlık kontrolü
                        sh 'aws s3api head-bucket --bucket petclinic-helm-charts-ersin --region us-east-1'
                        echo 'Bucket already exists'
                    } catch (Exception e) {
                        // Bucket yoksa oluştur
                        echo 'Bucket does not exist. Creating...'
                        sh 'aws s3api create-bucket --bucket petclinic-helm-charts-ersin --region us-east-1'
                        sh 'aws s3api put-object --bucket petclinic-helm-charts-ersin --key stable/myapp/'
                    }
                }
            }
        }
        stage('Create ECR Private Repo') {
            steps {
                echo "Creating ECR Private Repo for ${APP_NAME}"
                sh '''
                aws ecr describe-repositories --repository-name ${APP_REPO_NAME} --region $AWS_REGION || \
                    aws ecr create-repository \
                    --repository-name ${APP_REPO_NAME} \
                    --image-scanning-configuration scanOnPush=true \
                    --image-tag-mutability MUTABLE \
                    --region  $AWS_REGION
                '''
                }
        }
        stage('Package application') {
            agent {
                docker {
                    image 'maven:3.8.7-openjdk-18-slim'
                    args '-v $HOME/.m2:/root/.m2'
                    reuseNode true
                }
            }
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_PETCLINIC="${ECR_REGISTRY}/${APP_REPO_NAME}:ersin-petclinic-prod-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
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
}