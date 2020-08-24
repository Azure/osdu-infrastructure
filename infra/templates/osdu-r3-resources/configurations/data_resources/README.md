# Azure OSDU R3 - Data Resources Environment

The `osdu` - `data_resources` environment template is intended to provision to Azure resources used as a data partition.

Currently data partition isolation as part of the infratructure only supports 1 data partition but is architected in a way that is prepared for the future where multiple partitions may be available.

__PreRequisites__

Requires the use of [direnv](https://direnv.net/) for environment variable management.

## Deployment Steps

1. Set up your local environment variables

*Note: environment variables are automatically sourced by direnv*

Required Environment Variables (.envrc)
```bash
export ARM_TENANT_ID=""           
export ARM_SUBSCRIPTION_ID=""  

# Terraform-Principal
export ARM_CLIENT_ID=""
export ARM_CLIENT_SECRET=""

# Terraform State Storage Account Key
export TF_VAR_remote_state_account=""
export TF_VAR_remote_state_container=""
export ARM_ACCESS_KEY=""

# Instance Variables
export TF_VAR_resource_group_location="centralus"
export TF_VAR_cosmosdb_replica_location="eastus2"  # Region Pair Location
```

2. Execute the following command to configure your local Azure CLI.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
```

3. Navigate to the `terraform.tfvars` terraform file. Here's a sample of the terraform.tfvars file for this template.

```HCL
resource_group_location = "centralus"
prefix                  = "osdu"

storage_containers = [
  "data",
  "legal-service-azure-configuration",
  "opendes"
]

cosmos_db_name             = "osdu-data"
cosmosdb_consistency_level = "Session"
cosmosdb_replica_location  = "eastus2"
```

4. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="${USER}-dr"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

5. Execute the following commands to orchestrate a deployment.

```bash
# See what terraform will try to deploy without actually deploying
terraform plan

# Execute a deployment
terraform apply
```

## Testing

Please confirm that you've completed the `terraform apply` step before running the integration tests as we're validating the active terraform workspace.

Unit tests can be run using the following command:

```
go test -v $(go list ./... | grep "unit")
```

Integration tests can be run using the following command:

```
go test -v $(go list ./... | grep "integration")
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