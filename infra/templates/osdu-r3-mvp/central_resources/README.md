# Azure OSDU MVC - Central Resources Configuration

The `osdu` - `central_resources` environment template is intended to provision to Azure resources for OSDU which are typically central to the architecture and can't be removed without destroying the entire OSDU deployment. 

__PreRequisites__

Requires the use of [direnv](https://direnv.net/) for environment variable management.

Requires a preexisting Service Principal to be created to be used for this OSDU Environment.

```bash
ENV=$USER  # This is helpful to set to your expected OSDU environment name.
NAME="osdu-mvp-$ENV-principal"

# Create a Service Principal
az ad sp create-for-rbac --name $NAME --skip-assignment -ojson

# Result
{
  "appId": "<guid>",                # -> Use this for TF_VAR_principal_appId
  "displayName": "<name>",          # -> Use this for TF_VAR_principal_name
  "name": "http://<name>",
  "password": "****************",   # -> Use this for TF_VAR_principal_password
  "tenant": "<ad_tenant>"
}

# Retrieve the AD Application Metadata Information
az ad app list --display-name $NAME --query [].objectId -ojson

# Result
[
  "<guid>"                          # -> Use this for TF_VAR_principal_objectId
]


# Assign API Permissions
# Microsoft Graph -- Application Permissions -- Directory.Read.All  ** GRANT ADMIN-CONSENT
adObjectId=$(az ad app list --display-name $NAME --query [].objectId -otsv)
graphId=$(az ad sp list --query "[?appDisplayName=='Microsoft Graph'].appId | [0]" --all -otsv)
directoryReadAll=$(az ad sp show --id $graphId --query "appRoles[?value=='Directory.Read.All'].id | [0]" -otsv)=Role

az ad app permission add --id $adObjectId --api $graphId --api-permissions $directoryReadAll

# Grant Admin Consent
# ** REQUIRES ADMIN AD ACCESS **
az ad app permission admin-consent --id $appId 
```

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
prefix                  = "osdu-mvp"

resource_tags = {
   contact = "<your_name>"
}
```

3. Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="${USER}-cr"
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