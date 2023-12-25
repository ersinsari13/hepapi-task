### Spring-Petclinic (Ersin Sari)

# Cİ Pipeline with Jenkins
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

## Part 5 - Set up a Helm v3 chart repository in Github
- Create a GitHub repo and name it `chart-repo`.


- Create a GitHub repository in Jenkins User on Jenkins-server and push it.

```bash
mkdir chart-repo
cd chart-repo
echo "# chart-repo" >> README.md
git init
git add README.md
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/<your github name>/chart-repo.git
git push -u origin main
```

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
    targetRevision: "4" #update your revision number
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