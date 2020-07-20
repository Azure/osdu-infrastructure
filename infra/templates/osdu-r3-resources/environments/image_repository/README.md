# Azure Small Microservice Mesh on Elastic Cloud Enterprise - Image Registry Environment

The `az-micro-svc-small-elastic-cloud` - `image_registry` environment template is intended to provision Azure the Azure Container Registry resource. We decided to split these configuration files out into a separate Terraform module to 1) mitigate the risk of Terraform accidentally deleting stateful resources types and 2) This ACR resource is referenced across all Azure environment resources provisioned through the `container_cluster` and `managed_service` environments. 

> *Have you completed the quick start guide? Deploy your first infrastructure as code project with Cobalt by following the [quick-start guide](https://github.com/microsoft/cobalt/blob/master/docs/2_QUICK_START_GUIDE.md).*

## Technical Design
Template design [specifications](../../docs/design/README.md).

## Architecture
![Template Topology](../../docs/images/topology.png "Template Topology")

## Intended audience

Cloud administrators that's versed with Cobalt templating.

## Prerequisites

1. Azure Subscription
2. An available Service Principal with API Permissions granted with Admin Consent within Azure app registration. The required Azure Active Directory Graph app role is `Application.ReadWrite.OwnedBy`
![image](https://user-images.githubusercontent.com/7635865/74204636-9d0dde00-4c39-11ea-9943-2dd32bcd3322.png)
3. Terraform and Go are locally installed
4. Azure Storage Account is [setup](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) to store Terraform state
5. Local environment variables are [setup](https://github.com/microsoft/cobalt/blob/f31aff95e7732efde96c91b2779e94e16c1d538e/docs/2_QUICK_START_GUIDE.md#step-3-setup-local-environment-variables)
6. Deployment Service Principal is granted Owner level role assignment for the target Azure subscription
![image](https://user-images.githubusercontent.com/7635865/74204526-2ec91b80-4c39-11ea-8b1b-e5f1a61b473c.png)

## Cost

Azure environment cost ballpark [estimate](https://azure.com/e/92b05a7cd1e646368ab74772e3122500). This is subject to change and is driven from the resource pricing tiers configured when the template is deployed. 

## Deployment Steps

1. Execute the following commands to set up your local environment variables:

*Note for Windows Users using WSL*: We recommend running dos2unix utility on the environment file via `dos2unix .env` prior to sourcing your environment variables to chop trailing newline and carriage return characters.

```bash
# these commands setup all the environment variables needed to run this template
DOT_ENV=<path to your .env file>
export $(cat $DOT_ENV | xargs)
```

2. Execute the following command to configure your local Azure CLI.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
```

3. Navigate to the `terraform.tfvars` terraform file. Here's a sample of the terraform.tfvars file for this template.

```HCL
resource_group_name     = "osdu-r2-acr"
resource_group_location = "centralus"
container_registry_name = "osducr"
```

4. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="dev-int-env"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

5. Execute the following commands to orchestrate a deployment.

```bash
# See what terraform will try to deploy without actually deploying
terraform plan

# Execute a deployment
terraform apply
```

6. Optionally execute the following command to teardown your deployment and delete your resources.

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