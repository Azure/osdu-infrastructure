# Azure Small Microservice Mesh on Elastic Cloud Enterprise

The `az-micro-svc-small-elastic-cloud` template is intended to be a reference for running a small suite of public facing app services and functions which interface with [ECE](https://www.elastic.co/products/ece).

> *Have you completed the quick start guide? Deploy your first infrastructure as code project with Cobalt by following the [quick-start guide](https://github.com/microsoft/cobalt/blob/master/docs/2_QUICK_START_GUIDE.md).*

## Use-Case

This particular template creates an Azure environment with a small set of fully managed microservices backed by Azure Application Services with [API Management](https://docs.microsoft.com/en-us/azure/api-management/api-management-key-concepts) acting as the single ingress control plane. Our customer use-case had spatial data search requirements so Elasticsearch was an obvious choice. We decided to use ECE with the intent to follow ElasticSearch cluster setup and security best practices.

Servlerless Azure Functions are used for our data processing layer with [Azure Service Bus](https://azure.microsoft.com/en-us/services/service-bus/) as our Pub/Sub Solution.  

## Scenarios this template should avoid

This template is an adequate solution where the service count is less than 10. For Azure customers interested with provisioning more than 10 services, we recommend using AKS and [Bedrock](https://github.com/microsoft/bedrock). Reason being that with Kubernetes you can maximize cluster node CPU cores which helps minimize cloud resourcing costs.

## Technical Design
Template design [specifications](docs/design/README.md).

## Architecture
![Template Topology](docs/design/.design_images/deployment_topology.jpg "Template Topology")

## Intended audience

Cloud administrators that's versed with Cobalt templating.

## Prerequisites

1. Azure Subscription
2. An available Service Principal with API Permissions granted with Admin Consent within Azure app registration. The required Azure Active Directory Graph app role is `Application.ReadWrite.OwnedBy`
![image](https://user-images.githubusercontent.com/7635865/71312782-d9b91800-23f4-11ea-80ee-cc646f1c74be.png)
3. Terraform and Go are locally installed
4. Azure Storage Account is [setup](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) to store Terraform state
5. Local environment variables are [setup](https://github.com/microsoft/cobalt/blob/f31aff95e7732efde96c91b2779e94e16c1d538e/docs/2_QUICK_START_GUIDE.md#step-3-setup-local-environment-variables)

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
resource_group_location = "centralus"
prefix                  = "test-services"

# Targets that will be configured to also setup AuthN with Easy Auth
app_services = [
  {
    app_name = "tf-test-svc-1"
    image    = null
    app_settings = {
      "one_sweet_app_setting" = "brilliant"
    }
  },
  {
    app_name = "tf-test-svc-2"
    image    = null
    app_settings = {
      "another_sweet_svc_app_setting" = "ok"
    }
  }
]
```

4. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="$USER"
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

## Automated Testing

### Unit Testing 

Navigate to the template folder `infra/templates/az-micro-svc-small-elastic-cloud`. Unit tests can be run using the following command:

```
go test -v $(go list ./... | grep "unit")
```

### Integration Testing

Please confirm that you've completed the `terraform apply` step before running the integration tests as we're validating the active terraform workspace.

Integration tests can be run using the following command:

```
go test -v $(go list ./... | grep "integration")
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