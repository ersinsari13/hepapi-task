### Spring-Petclinic (Ersin Sari)

# CİCD Pipeline with Jenkins
- Jenkins Server

* Launch the jenkins server using `jenkins-server-tf-template` folder.

* After launch we will go on jenkins server. So, clone the project repo to the jenkins server.

```bash
git clone https://[github username]:[your-token]@github.com/[your-git-account]/[your-repo-name-petclinic-microservices-with-db.git
```

* Get the initial administrative password.

``` bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

* Enter the temporary password to unlock the Jenkins.

* Install suggested plugins.

* Create first admin user.

* Open your Jenkins dashboard and navigate to `Manage Jenkins` >> `Plugins` >> `Available` tab

* Search and select `GitHub Integration`,  `Docker`,  `Docker Pipeline`, `Email Extension` plugins, then click `Install without restart`. Note: No need to install the other `Git plugin` which is already installed can be seen under `Installed` tab.
### Set up a Helm v3 chart repository in Amazon S3

* This pattern helps us to manage Helm v3 charts efficiently by integrating the Helm v3 repository into Amazon Simple Storage Service (Amazon S3) on the Amazon Web Services (AWS) Cloud. 
(https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html)

```

* Install the helm-s3 plugin for Amazon S3.

```bash
helm plugin install https://github.com/hypnoglow/helm-s3.git
```

* On some systems we need to install ``Helm S3 plugin`` as Jenkins user to be able to use S3 with pipeline script.

``` bash
sudo su -s /bin/bash jenkins
export PATH=$PATH:/usr/local/bin
helm version
helm plugin install https://github.com/hypnoglow/helm-s3.git
exit
``` 

* ``Initialize`` the Amazon S3 Helm repository.

```bash
AWS_REGION=us-east-1 helm s3 init s3://petclinic-helm-charts-ersin/stable/myapp 
```

* The command creates an ``index.yaml`` file in the target to track all the chart information that is stored at that location.

* Verify that the ``index.yaml`` file was created.

```bash
aws s3 ls s3://petclinic-helm-charts-ersin/stable/myapp/
```

* Add the Amazon S3 repository to Helm on the client machine. 

```bash
helm repo ls
AWS_REGION=us-east-1 helm repo add stable-petclinicapp s3://petclinic-helm-charts-ersin/stable/myapp/
```

Create a PROD Environment on EKS Cluster
- ### Install eksctl

- Download and extract the latest release of eksctl with the following command.

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
```

- Move the extracted binary to /usr/local/bin.

```bash
sudo mv /tmp/eksctl /usr/local/bin
```

- Test that your installation was successful with the following command.

```bash
eksctl version
```

### Install kubectl

- Download the Amazon EKS vended kubectl binary.

```bash
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.7/2023-11-14/bin/linux/amd64/kubectl
```

- Apply execute permissions to the binary.

```bash
chmod +x ./kubectl
```

- Move the kubectl binary to /usr/local/bin.

```bash
sudo mv kubectl /usr/local/bin
```

- After you install kubectl , you can verify its version with the following command:

```bash
kubectl version --short --client
```

- Switch user to jenkins for creating eks cluster. Execute following commands as `jenkins` user.

```bash
sudo su - jenkins -s /bin/bash
```

- Create a `cluster.yaml` file under `/var/lib/jenkins` folder.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: petclinic-cluster
  region: us-east-1
availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]
managedNodeGroups:
  - name: ng-1
    instanceType: t3a.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    volumeSize: 8
```

- Create an EKS cluster via `eksctl`. It will take a while.

```bash
eksctl create cluster -f cluster.yaml
```

- After the cluster is up, run the following command to install `ingress controller`.

```bash
export PATH=$PATH:$HOME/bin
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```
### Configuration for HPA

This yaml file for HPA
```bash
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: petclinic-deploy-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: petclinic-deploy
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```
we need to install kubernetes — metric-server

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Then, before running the metric-server file, we add — kubelet-insecure-tls to the conponents.yaml file we downloaded to avoid getting an error when it is necessary to run it without a TLS certificate, as specified in the github documentation.

Then we run the yaml file that will run the metrics-server and after waiting 1–2 minutes, we see that the metrics that were unknow are now properly received.

```bash
kubectl apply -f components.yaml
```

### Install EBS CSI Driver on AWS EKS Cluster

- Create IAM Policy for EBS
- Associate IAM Policy to Worker Node IAM Role
- Install EBS CSI Driver

# Create IAM Policy for EBS
  - Go to Services -> IAM
  - Create a Policy
  - Select JSON tab and copy paste the below JSON
```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
```
- Click on Review Policy
- Name: Amazon_EBS_CSI_Driver
- Description: Policy for EC2 Instances to access Elastic Block Store
- Click on Create Policy

Get the IAM role Worker Nodes using and Associate this policy to that role
# Get Worker node IAM Role ARN

```bash
# Get Worker node IAM Role ARN
kubectl -n kube-system describe configmap aws-auth

# from output check rolearn
rolearn: arn:aws:iam::180789647333:role/eksctl-eksdemo1-nodegroup-eksdemo-NodeInstanceRole-IJN07ZKXAWNN
```
- Go to Services -> IAM -> Roles - Search for role with name eksctl-eksdemo1-nodegroup and open it - Click on Permissions tab - Click on Attach Policies - Search for Amazon_EBS_CSI_Driver and click on Attach Policy

# Deploy Amazon EBS CSI Driver

* Deploy Amazon EBS CSI Driver

```bash
# Deploy EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# Verify ebs-csi pods running
kubectl get pods -n kube-system
```
# Ci Pipeline with Jenkins CD Pipeline with ARGOCD

* Install Argo CD on EKS Cluster

```bash
# install ArgoCD in k8s
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# access ArgoCD UI
kubectl get svc -n argocd
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# login with admin user and below token (as in documentation):
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo

```
* Install Helm Chart by using Application.yml

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: petclinic
  namespace: argocd
spec:
  project: default
  source:
    chart: petclinic_chart
    targetRevision: "4"
    repoURL: https://raw.githubusercontent.com/ersinsari13/chart-repo/dev
    helm:
      releaseName: petclinic
  destination:
    server: "https://kubernetes.default.svc"
    namespace: myapp
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      selfHeal: true
      prune: true
```
### Deploying Your Nginx Server for Reverse proxy
We will configure Nginx as a reverse proxy and build a Docker image for it.

Create a separate folder called custom_nginx.This folder will house your Dockerfile for the Nginx image, and custom Nginx configuration files.

Next, Create a new file called nginx.conf in the custome_nginx folder. This file will hold the custom configurations for your reverse proxy server.

Add this block of code to the nginx.conf file:

```bash
events { }

http {

  server {
    listen 8080;

    location / {
      proxy_pass http://petclinic-service:8080/;
    }
  }
}
```
We are basically telling your Nginx server to listen on port 8080, and send any requests that come into the server with the path /flask to the kubernetes flask service http://petclinic-service:8080/ which you are going to set up in your kubernetes cluster.

Next, add the following block of code to your Dockerfile in the custom_nginx folder:

```bash
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
```
The Dockerfile instructs docker to copy your new nginx configuration file and replace the default nginx configuration file with it.

Create, and push us Docker image to DockerHub.
Finally port-forward to nginx-proxy service

```bash
kubectl port-forward svc/backend-svc 5000:5000
```