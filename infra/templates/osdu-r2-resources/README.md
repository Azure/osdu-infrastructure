# OSDU R2 Web App Microservice Architecture with Elastic Cloud SaaS

The `osdu-r2-resources` template is intended to deploy infrastructure necessary for the OSDU R2 Release using web apps for hosting the microservices and integrates with [Elastic Cloud](https://www.elastic.co/cloud/)


## Use-Case

This particular template creates an Azure environment with a small set of fully managed microservices backed by Azure Application Services. Our customer use-case had spatial data search requirements so Elasticsearch was an obvious choice. We had initially decided to use ECE with the intent to follow ElasticSearch cluster setup and security best practices, but moved later to ESS which is a hosted SaaS solution for Elastic Search.

Elastic Search Requirements require version 6.8.x and is currently tested against 6.8.3 with a valid SSL certificate on the endpoint.

A Servlerless Azure Function is used for our data processing layer with [Azure Service Bus](https://azure.microsoft.com/en-us/services/service-bus/) as our Pub/Sub Solution.  

## Scenarios this template should avoid

This template is an adequate solution where the service count is less than 10. For Azure customers interested with provisioning more than 10 services, we recommend using AKS and [Bedrock](https://github.com/microsoft/bedrock). Reason being that with Kubernetes you can maximize cluster node CPU cores which helps minimize cloud resourcing costs.  A future version anticipated with R3 will leverage AKS.

## Technical Design
Template design [specifications](docs/design/README.md).

## Architecture
![Template Topology](docs/design/.design_images/deployment_topology.jpg "Template Topology")

## Intended audience

Cloud administrators that's versed with Cobalt templating.

## Prerequisites

1. Azure Subscription
2. An available Service Principal with API Permissions granted with Admin Consent within Azure app registration. The required Azure Active Directory Graph app role is `Application.ReadWrite.OwnedBy`
![image](./docs/design/.design_images/TFPrincipal-Permissions.png)
3. Terraform and Go are locally installed
4. Azure Storage Account is [setup](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) to store Terraform state
5. Local environment variables are [setup](https://github.com/Azure/osdu-infrastructure/blob/master/docs/osdu/INFRASTRUCTURE_DEPLOYMENTS.md)

## Cost

Azure environment cost ballpark [estimate](https://azure.com/e/09aab61ac8cd43b48c54c9d7290473cc). This is subject to change and is driven from the resource pricing tiers configured when the template is deployed. 

## Deployment Steps

1. Execute the following commands to set up your local environment variables:

We recommend running [direnv](https://direnv.net/) for sourcing your environment variables.

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

3. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="$USER"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

4. Execute the following commands to orchestrate a deployment.

```bash
# See what terraform will try to deploy without actually deploying
terraform plan

# Execute a deployment
terraform apply
```


### Azure AD Application Admin Consent
>NOTE: This is a required Manual Step.

The deployment by default creates a Service Prinicpal with the naming convention <env_unique>.osdu-r2-ad-app-management.  This service principal requires the ability to access the Microsoft Graph API and a final manual step is required for an admin to grant-consent as described in the [Azure AD Application Management Documentation](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/grant-admin-consent#grant-admin-consent-in-app-registrations).


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