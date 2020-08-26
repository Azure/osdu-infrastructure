# Helm Installation Instructions

1. Download [helm-config.yaml](https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml), which will configure OSDU on Azure.

```bash
wget https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml -O config.yaml
```

2. Edit the newly downloaded [helm-config.yaml](https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml) and fill out the sections `azure` and `ingress`.

3. Install the osdu on azure charts.

```bash
# Full Install
helm install -f config.yaml osdu-current osdu-azure
```

_Alternately you can install each chart individually_

```bash
# Targeted Install
helm install -f helm-config.yaml osdu-common-current osdu-azure/charts/common
helm install -f helm-config.yaml entitlements-azure-current osdu-azure/charts/entitlements-azure
helm install -f helm-config.yaml legal-current osdu-azure/charts/legal
helm install -f helm-config.yaml storage-current osdu-azure/charts/storage
helm install -f helm-config.yaml indexer-queue-current osdu-azure/charts/indexer-queue
helm install -f helm-config.yaml indexer-current osdu-azure/charts/indexer
helm install -f helm-config.yaml search-current osdu-azure/charts/search
```