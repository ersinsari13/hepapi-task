echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml
cd /var/lib/jenkins/chart-repo
helm package /var/lib/jenkins/workspace/petclinic-argocd/k8s/petclinic_chart
helm repo index .
git add .
git commit "petclinic_chart-${BUILD_NUMBER}.tgz added"
git push origin dev