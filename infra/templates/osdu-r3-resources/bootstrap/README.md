# Bootstrap Template

## Overview

The `bootstrap` template for OSDU creates various Variable Groups required for OSDU Infrastructure
Templates.

The template connects to an existing OSDU AzDO project and requires a Personal Access Token (PAT) to
connect and create resources.

## Provisioned Resources

This deployment creates the following:

 1. Variable Groups that are defined for templates (Container Cluster (CC), Image Repository (IR),
 Data Storage (DS)) regardless of the environment (Dev, QA, etc.,)
 2. Variable Groups for Templates that are specific to an environment.

## Intended audience

This template is intended for an infrastructure engineer that wants to stand up or add new Variable
Groups for new or existing environments.

## Pattern Usage Scenario(s)

One time setup of Variable Groups at the time of start of the project or for setting up a new
environment.

## Example Usage

1. Set environment variables outlined in `.env.template` from your own `.env`, or manually enter.
    ```
    $ export $(cat .env | xargs)
    ```
    or
    ```
    $ AZDO_PERSONAL_ACCESS_TOKEN=<personal-access-token-for-the-project>
    $ AZDO_ORG_SERVICE_URL=<azdo-project-service-url>
    ```
2. Call the terraform `init`, `plan`, `apply` commands to initialize the terraform deployment then
write and apply the plan.

    ```shell
    $ terraform init && terraform plan -varfile='input-tfvars-file'
    $ # If things look good then...
    $ terraform apply
    ```

NB: The AzDO service URL should have the `https://dev.azure.com/<organization>/` format.

### Template Variables

In `terraform.tfvars`, there are a number of variables that will need defining.

 1. `environments`: Specifies a list of environments with properties targeting specific environments.
   - For each environment - `demo`, `prod`, etc. - the rest of the variables will need their own
   iteration. (See pattern below)
 2. `project_name`: Specifies the name of the AzDO project targeted.
 3. `project_id` : Project ID of the AzDO project. (Can't find it? It can be found here with a `GET
 https://dev.azure.com/{organization}/_apis/projects/`)
 4. `service_connection_name` : The name of the service connection used for the templates.
 5. `remote_state_account` : The name of the remote Terraform state account for the templates in the
  Variable Groups.
 6. `remote_state_container` : The name of the remote Terraform state container.
 7. `agent_pool` : The name and configuration for the agent pool.
 8. `resource_group_location` : The Azure region where all resources in this template should be
 created.
 9. `build_artifact_name` : Name of build artifact.
 10. `force_run` : Force Run variable setting.
 11. `randomization_level` : Level of Randomization setting.
 12. `warn_output_errors` : Warn Output Error setting.
 13. `cosmosdb_consistency_level` : CosmoDB consistency level setting.
 14. `cosmosdb_throughput` : CosmoDB throughput level setting.
 15. `cosmosdb_replica_location` : CosmoDB replica location setting.


 ```hcl
 environments = [
  {
    environment : "r3demo",
    az_sub_id : "...",
    aks_agent_vm_count : "...",
    data_sources_workspace : "...",
    flux_recreate : "true",
    gitops_ssh_url : "...",
    gitops_url_branch : "...",
    gitops_path : "providers/demo",
    image_repository_workspace_name : "...",
    cosmosdb_replica_location = "...",
    ssl_certificate_keyvault_id : "...",
    ssl_keyvault_id : "...",
    service_connection_name : "..."
  }]
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
