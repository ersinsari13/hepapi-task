docker build --force-rm -t "${IMAGE_TAG_PETCLINIC}" .
docker build --force-rm -t "${IMAGE_TAG_GRAFANA_SERVICE}" "${WORKSPACE}/pro-gra/grafana"
docker build --force-rm -t "${IMAGE_TAG_PROMETHEUS_SERVICE}" "${WORKSPACE}/progra/prometheus"