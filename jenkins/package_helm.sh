echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart_local/values-template.yaml > k8s/petclinic_chart_local/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart_local/Chart.yaml
cd /var/lib/jenkins/chart-repo
helm package /var/lib/jenkins/workspace/petclinic-argocd-local/k8s/petclinic_chart_local
helm repo index .
git add .
git commit -m "petclinic_chart_local-${BUILD_NUMBER}.tgz added"
git push origin dev