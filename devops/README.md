# Helm Installation Instructions

1. Download [helm-config.yaml](https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml), which will configure OSDU on Azure.

```bash
wget https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml -O config.yaml
```

2. Edit the newly downloaded [config.yaml](https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml) and fill out the sections `azure` and `ingress`.

3. Manually extract the manifests from the helm charts to your Flux Repo Directory.

```bash
SRC_DIR="<ROOT_PATH_TO_SOURCE>"      #  $HOME/source/osdu
FLUX_SRC="<FULL_PATH_TO_SOURCE>"     #  $SRC_DIR/k8-gitops-manifests
INFRA_SRC="<FULL_PATH_TO_SOURCE>"    #  $SRC_DIR/osdu-infrastructure
SERVICES_DIR="<FULL_PATH_TO_SOURCE>" #  $SRC_DIR/osdu-gitlab
BRANCH="master"
TAG="latest"

# Extract manifests from the common osdu chart.
helm template osdu-flux ${INFRA_SRC}/devops/charts/osdu-common -f ${INFRA_SRC}/devops/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/azure-common.yaml

# Extract manifests from each service chart.
for SERVICE in entitlements-azure legal storage indexer-service indexer-queue search-service ;
do
  helm template $SERVICE ${SERVICES_DIR}/$SERVICE/devops/azure/chart --set image.branch=$BRANCH --set image.tag=$TAG > ${FLUX_SRC}/providers/azure/hld-registry/$SERVICE.yaml
done

# Extract manifests for Istio
helm template osdu-flux ${INFRA_SRC}/devops/charts/osdu-istio -f ${INFRA_SRC}/devops/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/osdu-istio.yaml
helm template osdu-flux ${INFRA_SRC}/devops/charts/osdu-istio-auth -f ${INFRA_SRC}/devops/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/osdu-istio-auth.yaml
```
