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
1. Local environment variables are [setup](https://github.com/microsoft/cobalt/blob/f31aff95e7732efde96c91b2779e94e16c1d538e/docs/2_QUICK_START_GUIDE.md#step-3-setup-local-environment-variables)
1. Deployment Service Principal is granted Owner level role assignment for the target Azure subscription
![image](../../../docs/osdu/images/service_principal.png)
1. Enroll as an Azure subscriber. The free trial subscription does not support enough cores to run this tutorial.
1. Terraform `common_resources` environment module is [provisoned](environments/common_resources/README.md) to your Azure Environment
1. Terraform `data_resources` environment module is [provisoned](environments/data_resources/README.md) to your Azure Environment
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

Copy the manifests located in /devops/manifests to the providers/azure/hld-registry directory.

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

# Deployment Steps

## Deploy Resources using Azure DevOps Pipelines

__Elastic Search Setup__

Infrastructure assumes bring your own Elastic Search Instance at a version of `6.8.x` and access information must be stored in a Common KeyVault.


```bash
AZURE_VAULT="<your_keyvault>"
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-endpoint-osdu-r3-env" --value <your_es_endpoint>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-username-osdu-r3-env" --value <your_es_username>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-password-osdu-r3-env" --value <your_es_password>

# This command will extract all Key Vault Secrets
for i in `az keyvault secret list --vault-name $AZURE_VAULT --query [].id -otsv`
do
   echo "export ${i##*/}=\"$(az keyvault secret show --vault-name $AZURE_VAULT --id $i --query value -otsv)\""
done

```
> The Elastic endpoint provided should include `https` and the appropriate port number. A `http` endpoint will not work. 

### Configure Azure DevOps Service Connection

- Configure an [ARM Resources Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops)
with name `osdu-infrastructure` for the desired subscription.
> ADO -> Project Settings -> Service Connection -> New service connection -> Azure Resource Manager -> Service principal (automatic)

  - Scope should be to the desired Subscription but do not apply scope to a Resource Group

- Locate the Service Principal created (<organization-project-subscription>) in Azure Active Directory and elevate the principal capability by adding in 2 API Permissions
  - Azure Active Directory Graph - Application.ReadWrite.OwnedBy
  - Microsoft Graph - Application.ReadWrite.OwnedBy

> These 2 API's require `Grant Admin Consent`


### Setup ADO required Libraries

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables`

  | Variable | Value |
  |----------|-------|
  | AGENT_POOL | Hosted Ubuntu 1604 |
  | BUILD_ARTIFACT_NAME | osdu-infrastructure |
  | SERVICE_CONNECTION_NAME | osdu-infrastructure |
  | TF_VAR_elasticsearch_secrets_keyvault_name | osducommon<your_unique>-kv |
  | TF_VAR_elasticsearch_secrets_keyvault_resource_group | osdu-common-<your_unique> |
  | TF_VAR_remote_state_account | osducommon<your_unique> |
  | TF_VAR_remote_state_container | remote-state-container |

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables - env`

  | Variable | Value |
  |----------|-------|
  | ARM_SUBSCRIPTION_ID | <your_subscription_id> |
  | TF_VAR_aks_agent_vm_count | 3 |
  | TF_VAR_common_resources_workspace_name | cr-env |
  | TF_VAR_cosmosdb_replica_location | eastus2 |
  | TF_VAR_data_resources_workspace_name | dr-env |
  | TF_VAR_elasticsearch_version | 6.8.12 |
  | TF_VAR_gitops_branch | master |
  | TF_VAR_gitops_ssh_url | git@<your_flux_manifest_repo> |
  | TF_VAR_resource_group_location | centralus |

> You can specify the desired region locations you wish. Change the Elastic version as required.

- Setup and Configure the ADO Library `Infrastructure Pipeline Secrets - env`

  | Variable | Value |
  |----------|-------|
  | elastic-endpoint-osdu-r3-env | `*********` |
  | elastic-username-osdu-r3-env | `*********` |
  | elastic-password-osdu-r3-env | `*********` |

> This should be linked Secrets from Azure Key Vault `osducommon<your_unique>-kv`

- Setup 2 Secure Files
  - azure-aks-gitops-ssh-key
  - azure-aks-node-ssh-key.pub

> These files were created above.

- Add a Pipeline __osdu-infrastructure-r3-common__ -->  `azure-pipeline-common.yml` and execute it.

- Add a Pipeline __osdu-infrastructure-r3-data__ -->  `azure-pipeline-data.yml` and execute it.

- Add a Pipeline __osdu-infrastructure-r3-services__ -->  `azure-pipeline-services.yml` and execute it.

- Once Infrastructure is deployed grant admin_consent to the Service Principal.


## Manually Deployment Processes

Follow the directions in the [`common_resources`](./environments/common_resources/README.md) environment.

Follow the directions in the [`data_resources`](/environments/data_resources/README.md) environment.

Follow the directions in the [`cluster_resources`](./environments/cluster_resources/README.md) environment.


## Interact with the Deployed Cluster

After `terraform apply` finishes for the cluster_resources, there is one critical output artifact: the Kubernetes config file for the deployed cluster that is generated and saved in the output directory. The default file is output/bedrock_kube_config. The following steps use this file to interact with the deployed Bedrock AKS cluster.

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



## Integration Testing

Please confirm that you've completed the `terraform apply` step before running the integration tests as we're validating the active terraform workspace.

Integration tests can be run using the following command:

```
go test -v $(go list ./... | grep "integration")
```

## Terraform Destroy 

Optionally execute the following command to teardown your deployment and delete your resources.

```bash
# Destroy resources and tear down deployment. Only do this if you want to destroy your deployment.
terraform destroy
```

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