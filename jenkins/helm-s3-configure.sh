helm plugin install https://github.com/hypnoglow/helm-s3.git
AWS_REGION=us-east-1 helm s3 init s3://petclinic-helm-charts-ersin/stable/myapp
AWS_REGION=us-east-1 helm repo add stable-petclinicapp s3://petclinic-helm-charts-ersin/stable/myapp/