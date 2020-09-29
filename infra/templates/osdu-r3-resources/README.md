# Azure OSDU AKS Architecture Solution with Elastic Cloud SaaS

The `osdu` - Kubernetes Architecture solution template is intended to provision Managed Kubernetes resources like AKS and other core OSDU cloud managed services like Cosmos, Blob Storage and Keyvault. 

We decided to split these configuration files out into a separate Terraform environment templates to mitigate the risk of Terraform accidentally deleting stateful resources types as well as have a mechanism to duplicate environments to support concepts such as data partitioning or multiple AKS Clusters.


## Technical Design
Technical design [specifications](docs/aks-environment.md)

## GitOps Design
GitOps design [specifications](../../../docs/osdu/GITOPS_DESIGN.md).

## Cloud Resource Architecture

![Architecture](./docs/images/architecture.png "Architecture")

## Resource Topology

![Resource Topology](./docs/images/topology.png "Resource Topology")

## Terraform Template Topology

![Template Topology](./docs/images/template.png "Terraform Template Topology")

## Intended audience

Cloud administrators who are versed with both Cobalt templating and Kubernetes.

## Prerequisites

1. Azure Subscription
1. An available Service Principal with API Permissions granted with Admin Consent within Azure app registration. The required Azure Active Directory Graph app role is `Application.ReadWrite.OwnedBy`
![image](../../../docs/osdu/images/service_principal_permissions.png)
1. Terraform and Go are locally installed
1. Azure Storage Account is [setup](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) to store Terraform state
1. Local environment variables are [setup](docs/setup-environment-variables.md)
1. Deployment Service Principal is granted Owner level role assignment for the target Azure subscription
![image](../../../docs/osdu/images/service_principal.png)
1. Enroll as an Azure subscriber. The free trial subscription does not support enough cores to run this tutorial.
1. Terraform `common_resources` environment module is [provisoned](configurations/common_resources/README.md) to your Azure Environment
1. Terraform `data_resources` environment module is [provisoned](configurations/data_resources/README.md) to your Azure Environment
1. Install the required common tools (kubectl, helm, and terraform). See also [Required Tools](https://github.com/microsoft/bedrock/tree/master/cluster). Note: this tutorial currently uses [Terraform 0.12.28](https://releases.hashicorp.com/terraform/0.12.28/).

### Install the required tooling

This document assumes one is running a current version of Ubuntu. Windows users can install the [Ubuntu Terminal](https://www.microsoft.com/store/productId/9NBLGGH4MSV6) from the Microsoft Store. The Ubuntu Terminal enables Linux command-line utilities, including bash, ssh, and git that will be useful for the following deployment. _Note: You will need the Windows Subsystem for Linux installed to use the Ubuntu Terminal on Windows_.

Ensure that the [required tools](https://github.com/microsoft/bedrock/tree/master/cluster#required-tools), are installed in your environment. Alternatively, there are [scripts](https://github.com/microsoft/bedrock/tree/master/tools/prereqs) that will install `helm`, `terraform` and `kubectl`. In this case, use `setup_kubernetes_tools.sh` and `setup_terraform.sh`. The scripts install the tools into `/usr/local/bin`.

### Install the Azure CLI

For information specific to your operating system, see the [Azure CLI install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). You can also use [this script](https://github.com/microsoft/bedrock/blob/master/tools/prereqs/setup_azure_cli.sh) if running on a Unix based machine.


# Set Up Flux Manifest Repository

We will deploy the Bedrock environment using the empty repo and then add a Kubernetes manifest that defines a simple Web application. The change to the repo will automatically update the deployment.

To prepare the Flux manifest repository, we must:

1. [Create the Flux Manifest Repository](#create-the-flux-manifest-repository)
2. [Generate an RSA Key Pair to use as the Manifest Repository Deploy Key](#generate-an-rsa-key-pair-to-use-as-the-manifest-repository-deploy-key)
3. [Grant Deploy Key access to the Manifest Repository](#grant-deploy-key-access-to-the-manifest-repository)

## Create the Flux Manifest Repository

[Create an empty git repository](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops) with a name that clearly signals that the repo is used for the Flux manifests. For example `bedrock-deploy-demo`.

Flux requires that the git repository have at least one commit. Initialize the repo with an empty commit.

```bash
git commit --allow-empty -m "Initializing the Flux Manifest Repository"
```

When you are deploying services, you will put the manifests in providers/azure/hld-registry directory of this repo. Once you push the manifests, Flux should automatically deploy the services.

## Generate an RSA Key Pair to use as the Manifest Repository Deploy Key

Generate the [deploy key](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys) using `ssh-keygen`. The public portion of the key pair will be uploaded to GitHub as a deploy key.

```bash
AZURE_VAULT=<common_vault_name>
KEY_NAME=gitops-ssh-key

# Generate gitops-ssh-key
ssh-keygen -b 4096 -t rsa -f $KEY_NAME

# Save gitops-ssh-key
az keyvault secret set --vault-name $AZURE_VAULT -n "${KEY_NAME}" -f "${KEY_NAME}"
az keyvault secret set --vault-name $AZURE_VAULT -n "${KEY_NAME}-pub" -f "${KEY_NAME}.pub"

# Show Public gitops-ssh-key
az keyvault secret show --vault-name $AZURE_VAULT -n "${KEY_NAME}-pub" --query value -otsv
```


This will create public and private keys for the Flux repository. We will assign the public key under the following heading: [Adding the Repository Key](#adding-the-repository-key). The private key is stored on the machine originating the deployment.


## Configure Key Access in ADO

The public key of the [RSA key pair](#create-an-rsa-key-pair-for-a-deploy-key-for-the-flux-repository) previously created needs to be added as a deploy key. Note: _If you do not own the repository, you will have to fork it before proceeding_.

Use the contents of the Secret as shown above.


Next, in your Azure DevOPS Project, follow these [steps](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops&tabs=current-page#step-2--add-the-public-key-to-azure-devops-servicestfs) to add your public SSH key to your ADO environment.

## Create an RSA Key Pair to use as Node Key

The Terraform scripts use this node key to setup log-in credentials on the nodes in the AKS cluster. We will use this key when setting up the Terraform deployment variables. Generate the Node Key:

```bash
AZURE_VAULT=<common_vault_name>
KEY_NAME=node-ssh-key

# Generate node-ssh-key
ssh-keygen -b 4096 -t rsa -f $KEY_NAME

# Save node-ssh-key
az keyvault secret set --vault-name $AZURE_VAULT -n "${KEY_NAME}" -f "${KEY_NAME}"
az keyvault secret set --vault-name $AZURE_VAULT -n "${KEY_NAME}-pub" -f "${KEY_NAME}.pub"

# Save Locally Public node-ssh-key
az keyvault secret show --vault-name $AZURE_VAULT -n "${KEY_NAME}-pub" --query value -otsv
```


## Configure GitOPS + Node SSH keys with Terraform Deployment


Download the required keys from the common Key Vault

```
AZURE_VAULT=<common_vault_name>

az keyvault secret show --vault-name $AZURE_VAULT -n "node-ssh-key-pub" --query value -otsv > ~/.ssh/node-ssh-key.pub
az keyvault secret show --vault-name $AZURE_VAULT -n "gitops-ssh-key" --query value -otsv > ~/.ssh/gitops-ssh-key
chmod 644 ~/.ssh/node-ssh-key.pub
chmod 600 ~/.ssh/gitops-ssh-key
```


Update your `.env` file with the paths to your public and private SSH keys for Node and GitOPS repo access.

```
TF_VAR_ssh_public_key_file=/home/$USER/.ssh/node-ssh-key.pub
TF_VAR_gitops_ssh_key_file=/home/$USER/.ssh/gitops-ssh-key
```

## Deploy Infrastructure using Azure Dev Ops Pipelines
Follow the directions in [here](docs/deploy-infrastructure-using-pipelines.md).


## Manually Deploy Infrastructure

Follow the directions in the [`common_resources`](configurations/common_resources/README.md) environment.

Follow the directions in the [`data_resources`](configurations/data_resources/README.md) environment.

Follow the directions in the [`service_resources`](./configurations/service_resources/README.md) environment.


## Interact with the Deployed Cluster

After `terraform apply` finishes for the service_resources, there is one critical output artifact: the Kubernetes config file for the deployed cluster that is generated and saved in the output directory. The default file is output/bedrock_kube_config. The following steps use this file to interact with the deployed Bedrock AKS cluster.

Using the config file output/bedrock_kube_config, one of the first things we can do is list all pods deployed within the cluster:

```bash
KUBECONFIG=./output/bedrock_kube_config kubectl get po --all-namespaces

NAMESPACE      NAME                                                READY   STATUS    RESTARTS   AGE
agic           agic-ingress-azure-7b88b4b69f-p9n5w                 1/1     Running   0          15d
cert-manager   jetstack-cert-manager-567bb678c7-sjmct              1/1     Running   0          21h
cert-manager   jetstack-cert-manager-cainjector-695d847cdd-l2rv6   1/1     Running   0          21h
cert-manager   jetstack-cert-manager-webhook-5b895bb689-dvwvd      1/1     Running   0          21h
flux           flux-6899458bb8-qghrq                               1/1     Running   8          15d
flux           flux-memcached-8647794c5f-slsvr                     1/1     Running   0          15d
keda           keda-operator-5895ff46b9-fh5xn                      1/1     Running   0          3d3h
keda           keda-operator-metrics-apiserver-6774776dbc-jwg7q    1/1     Running   0          8d
kube-system    azure-cni-networkmonitor-745vs                      1/1     Running   0          15d
kube-system    azure-cni-networkmonitor-9kq6c                      1/1     Running   0          15d
kube-system    azure-cni-networkmonitor-dt7ch                      1/1     Running   0          15d
kube-system    azure-ip-masq-agent-6kv6v                           1/1     Running   0          15d
kube-system    azure-ip-masq-agent-p6zxn                           1/1     Running   0          15d
kube-system    azure-ip-masq-agent-vw7fr                           1/1     Running   0          15d
kube-system    azure-npm-f9qz7                                     1/1     Running   0          10d
kube-system    azure-npm-j6qdv                                     1/1     Running   0          10d
kube-system    azure-npm-vkghz                                     1/1     Running   0          10d
kube-system    coredns-869cb84759-69nmv                            1/1     Running   0          15d
kube-system    coredns-869cb84759-fvpf8                            1/1     Running   0          15d
kube-system    coredns-autoscaler-5b867494f-wvt6q                  1/1     Running   11         15d
kube-system    dashboard-metrics-scraper-7dbbb6996d-4v6m4          1/1     Running   0          15d
kube-system    kube-proxy-4qmfg                                    1/1     Running   0          15d
kube-system    kube-proxy-b66qd                                    1/1     Running   0          15d
kube-system    kube-proxy-wwts4                                    1/1     Running   0          15d
kube-system    kubernetes-dashboard-5596bdb9f-cx4bw                1/1     Running   8          15d
kube-system    metrics-server-6cd7558856-lvqrg                     1/1     Running   0          15d
kube-system    omsagent-4g9qf                                      1/1     Running   0          15d
kube-system    omsagent-j8v77                                      1/1     Running   0          15d
kube-system    omsagent-rs-764c6f8d8-54fjd                         1/1     Running   0          15d
kube-system    omsagent-zg2wh                                      1/1     Running   0          15d
kube-system    tunnelfront-7cfc889c77-gh9jv                        2/2     Running   1          15d
kvsecrets      kvsecrets-csi-secrets-store-provider-azure-ddnwn    1/1     Running   0          15d
kvsecrets      kvsecrets-csi-secrets-store-provider-azure-j2m7x    1/1     Running   0          15d
kvsecrets      kvsecrets-csi-secrets-store-provider-azure-sszrt    1/1     Running   0          15d
kvsecrets      kvsecrets-secrets-store-csi-driver-92n8k            3/3     Running   0          15d
kvsecrets      kvsecrets-secrets-store-csi-driver-pnx8x            3/3     Running   0          15d
kvsecrets      kvsecrets-secrets-store-csi-driver-vmg48            3/3     Running   0          15d
osdu           default-service-86cd47b748-7mrnw                    1/1     Running   0          14d
osdu           entitlements-azure-cb59875bc-ncqll                  1/1     Running   0          8d
osdu           function-debug                                      1/1     Running   0          3d4h
osdu           indexer-7dfcdfbb-bf7sl                              1/1     Running   0          30h
osdu           legal-57cbd6cd66-tx6sf                              1/1     Running   0          8d
osdu           legal-debug                                         1/1     Running   0          9d
osdu           search-5f59bc7c85-5wc4l                             1/1     Running   0          27h
osdu           storage-7d794b54cf-2w5cn                            1/1     Running   0          47h
podidentity    aad-pod-identity-mic-57dbd9f4fb-bd4vr               1/1     Running   12         15d
podidentity    aad-pod-identity-mic-57dbd9f4fb-zj6lb               1/1     Running   0          15d
podidentity    aad-pod-identity-nmi-fmjlk                          1/1     Running   0          15d
podidentity    aad-pod-identity-nmi-qk2t4                          1/1     Running   0          15d
podidentity    aad-pod-identity-nmi-vtxmg                          1/1     Running   0          15d
```

Note that there is also a namespace flux. As previously mentioned, Flux is managing the deployment of all of the resources into the cluster. Taking a look at the description for the flux pod flux-5897d4679b-tckth, we see the following:

```bash
$ KUBECONFIG=./output/bedrock_kube_config kubectl describe po/flux-5897d4679b-tckth --namespace=flux
Name:               flux-5897d4679b-tckth
Namespace:          flux
Priority:           0
PriorityClassName:  <none>
Node:               aks-default-30249513-2/10.10.1.66
Start Time:         Tue, 18 Jun 2019 06:32:49 +0000
Labels:             app=flux
                    pod-template-hash=5897d4679b
                    release=flux
Annotations:        <none>
Status:             Running
IP:                 10.10.1.76
Controlled By:      ReplicaSet/flux-5897d4679b
Containers:
  flux:
    Container ID:  docker://cc4cf38387a883f964cc65b9a1dd13439be756be3cf2d84fa1ca2ced69d98c3a
    Image:         docker.io/weaveworks/flux:1.12.2
    Image ID:      docker-pullable://weaveworks/flux@sha256:368bc5b219feffb1fe00c73cd0f1be7754591f86e17f57bc20371ecba62f524f
    Port:          3030/TCP
    Host Port:     0/TCP
    Args:
      --ssh-keygen-dir=/var/fluxd/keygen
      --k8s-secret-name=flux-ssh
      --memcached-hostname=flux-memcached
      --memcached-service=
      --git-url=git@github.com:jmspring/manifests.git
      --git-branch=master
      --git-path=prod
      --git-user=Weave Flux
      --git-email=support@weave.works
      --git-set-author=false
      --git-poll-interval=5m
      --git-timeout=20s
      --sync-interval=5m
      --git-ci-skip=false
      --registry-poll-interval=5m
      --registry-rps=200
      --registry-burst=125
      --registry-trace=false
    State:          Running
      Started:      Tue, 18 Jun 2019 06:33:18 +0000
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:     50m
      memory:  64Mi
    Environment:
      KUBECONFIG:  /root/.kubectl/config
    Mounts:
      /etc/fluxd/ssh from git-key (ro)
      /etc/kubernetes/azure.json from acr-credentials (ro)
      /root/.kubectl from kubedir (rw)
      /var/fluxd/keygen from git-keygen (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from flux-token-d2h55 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kubedir:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      flux-kube-config
    Optional:  false
  git-key:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  flux-ssh
    Optional:    false
  git-keygen:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  acr-credentials:
    Type:          HostPath (bare host directory volume)
    Path:          /etc/kubernetes/azure.json
    HostPathType:
  flux-token-d2h55:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  flux-token-d2h55
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From                             Message
  ----    ------     ----   ----                             -------
  Normal  Scheduled  3m30s  default-scheduler                Successfully assigned flux/flux-5897d4679b-tckth to aks-default-30249513-2
  Normal  Pulling    3m22s  kubelet, aks-default-30249513-2  pulling image "docker.io/weaveworks/flux:1.12.2"
  Normal  Pulled     3m12s  kubelet, aks-default-30249513-2  Successfully pulled image "docker.io/weaveworks/flux:1.12.2"
  Normal  Created    2m57s  kubelet, aks-default-30249513-2  Created container
  Normal  Started    2m57s  kubelet, aks-default-30249513-2  Started container
```

## Continuous Deployment

Flux automation makes it easy to upgrade services or infrastructure deployed by Bedrock. In this example Flux watches the repo we set up previously under the heading [Set Up Flux Manifest Repository](#set-up-flux-manifest-repository). Now we add a simple Web application to the running deployment by pushing a .yaml manifest to the repo. The .yaml specification describes the service mywebapp and type: a LoadBalancer. It specifies the source the Docker image that contains it: image: andrebriggs/goserver:v1.2 and how many containers to run: replicas: 3. The containers will be accessible through the load balancer.

When the .yaml file is complete we will push it to the repo, or simply drop it on GitHub. Flux is querying the repo for changes and will deploy the new service replicas as defined by this manifest.

Create the following .yaml file and name it something like myWebApp.yaml. The image for this application is specified by the line: image: andrebriggs/goserver:v1.2.

```yaml
# mywebapp services
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: mywebapp
  labels:
    app: mywebapp
spec:
  type: LoadBalancer
  ports:
    - port: 8080
      name: http
  selector:
    app: mywebapp
---
apiVersion: extensions/v1beta1 #TODO: Migrate to apps/v1
kind: Deployment
metadata:
  name: mywebapp-v1
spec:
  replicas: 3
  minReadySeconds: 10 # Wait 2 seconds after each new pod comes up before marked as "ready"
  strategy:
    type: RollingUpdate # describe how we do rolling updates
    rollingUpdate:
      maxUnavailable: 1 # When updating take one pod down at a time
      maxSurge: 1 # When updating never have more than one extra pod. If replicas = 2 then never 3 pods when updating
  template:
    metadata:
      labels:
        app: mywebapp
        version: v1
    spec:
      containers:
        - name: mywebapp
          image: andrebriggs/goserver:v1.2
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
---

```

To see the changes as Flux picks them up and deploys them, open a bash command window and navigate to the `bedrock/cluster/environments/azure-simple` directory.

Get your Flux pod name by running: `KUBECONFIG=./output/bedrock_kube_config kubectl get pod -n flux`

Copy the name of the pod (the one that is not memcached).

Then run the command: `KUBECONFIG=./output/bedrock_kube_config kubectl logs -f <Flux-pod-name> --namespace=flux`. This will display a running log of the deployment.

Now, push or drop the myWebApp.yaml file to the empty repo created under the previous heading [Set Up Flux Manifest Repository](#set-up-flux-manifest-repository). You can click `Upload files` on the GitHub repo page and drop the .yaml file:

In this output, Flux has found the repo `bedrock-deploy-demo` and created the new service: `"kubectl apply -f -" took=1.263687361s err=null output="service/mywebapp created\ndeployment.extensions/mywebapp-v1 created"`.

Open another bash window. When the new service is running, use `KUBECONFIG=./output/bedrock_kube_config kubectl get po --all-namespaces` to find the new namespaces in the deployment.

Then run `KUBECONFIG=./output/bedrock_kube_config kubectl get svc --all-namespaces`. The output will include the `EXTERNAL-IP` address and `PORT` of the `mywebapp` load balancer:

```bash
$ KUBECONFIG=./output/bedrock_kube_config kubectl get svc --all-namespaces
NAMESPACE     NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)          AGE
default       kubernetes             ClusterIP      10.0.0.1       <none>           443/TCP          44m
default       mywebapp               LoadBalancer   10.0.96.208    http://168.61.208.215/   8080:30197/TCP   23m
flux          flux                   ClusterIP      10.0.139.133   <none>           3030/TCP         34m
flux          flux-memcached         ClusterIP      10.0.246.230   <none>           11211/TCP        34m
kube-system   kube-dns               ClusterIP      10.0.0.10      <none>           53/UDP,53/TCP    44m
kube-system   kubernetes-dashboard   ClusterIP      10.0.222.104   <none>           80/TCP           44m
kube-system   metrics-server         ClusterIP      10.0.189.185   <none>           443/TCP          44m
```

The EXTERNAL-IP, in this case is: http://168.61.208.215/. Append the port and use http://http://168.61.208.215:8080 to run the service in a browser.

![image](https://user-images.githubusercontent.com/7635865/74478125-55be6200-4e72-11ea-957f-dab2c663034a.png)

## Deploying OSDU Services
There are six OSDU services that can be deployed in this infrastructure: storage, search, indexer-serivce, indexer-queue, entitlements, and legal. The helm charts for these service can be found in their respective repos at /devops/azure:
* [Storage](https://community.opengroup.org/osdu/platform/system/storage/-/tree/master/devops/azure)
* [Search](https://community.opengroup.org/osdu/platform/system/search-service/-/tree/master/devops/azure)
* [Entitlements](https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements-azure/-/tree/master/devops/azure)
* [Legal](https://community.opengroup.org/osdu/platform/security-and-compliance/legal/-/tree/master/devops/azure)
* [Indexer Service](https://community.opengroup.org/osdu/platform/system/indexer-queue/-/tree/master/devops/azure)
* [Indexer Queue](https://community.opengroup.org/osdu/platform/system/indexer-queue/-/tree/master/devops/azure)

You can download the config file for these templates here: `wget https://raw.githubusercontent.com/Azure/osdu-infrastructure/master/devops/helm-config.yaml -O config.yaml`

To install the services using Flux, you will want a directory stucture like the following: 
```
project root
└───osdu-infrastructure (this repo)
└───osdu-services (folder you create)
|    └───entitlements-azure (service repo you will clone)
|    └───legal (service repo you will clone)
|    └───storage (service repo you will clone)
|    └───indexer-service (service repo you will clone)
|    └───indexer-queue (service repo you will clone)
|    └───search-service (service repo you will clone)
└───flux-repo (the repo for flux manifests you created earlier)
```
You can then use this script to generate the manifests in your flux repo after filling out your config.yaml file:
```bash
SRC_DIR="<ROOT_PATH_TO_SOURCE>"      #  $HOME/source/osdu
FLUX_SRC="<FULL_PATH_TO_SOURCE>"     #  $SRC_DIR/flux-repo
INFRA_SRC="<FULL_PATH_TO_SOURCE>"    #  $SRC_DIR/osdu-infrastructure
SERVICES_DIR="<FULL_PATH_TO_SOURCE>" #  $SRC_DIR/osdu-services
BRANCH="master"
TAG="latest"

# Extract manifests from the common osdu chart.
helm template osdu-flux ${INFRA_SRC}/devops/charts/osdu-common -f ${INFRA_SRC}/devops/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/azure-common.yaml

# Extract manifests from each service chart.
for SERVICE in entitlements-azure legal storage indexer-service indexer-queue search-service ;
do
  helm template $SERVICE ${SERVICES_DIR}/$SERVICE/devops/azure/chart --set image.branch=$BRANCH --set image.tag=$TAG > ${FLUX_SRC}/providers/azure/hld-registry/$SERVICE.yaml
done
```
After running this script, verify that the manifests are in your flux repo in the hld-registry directory and that the azure-common manifest is there as well. After verifying that these manifests are all in place, you can deploy the service by pushing the flux repo with the new files.

## Kubernetes Portal Dashboard

Kubernetes includes a web dashboard that can be used for basic management operations. This dashboard lets you view basic health status and metrics for your applications, create and deploy services, and edit existing applications.

```bash
$ kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

$ az aks browse --resource-group myResourceGroup --name myAKSCluster
The behavior of this command has been altered by the following extension: aks-preview
Merged "devint-aks-mgf9wjxt-osdu-r2-aks" as current context in /tmp/tmps6_a6amm
Proxy running on http://127.0.0.1:8001/
Press CTRL+C to close the tunnel...
```

![image](https://user-images.githubusercontent.com/7635865/74479484-d54d3080-4e74-11ea-8160-ec4e087597ae.png)



## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.