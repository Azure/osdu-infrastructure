# Azure OSDU MVC - Data Partition Configuration

The `osdu` - `data_partition` template is intended to provision to Azure resources for an OSDU Data Partition. 


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
```

2. Navigate to the `terraform.tfvars` terraform file. Here's a sample of the terraform.tfvars file for this template.

```HCL
prefix = "osdu-mvp"

resource_tags = {
  contact = "<your_name>"
}

# Storage Settings
storage_shares = [ "airflowdags" ]
storage_queues = [ "airflowlogqueue" ]
```

3. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="${USER}-dp1"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

4. Execute the following commands to orchestrate a deployment.

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