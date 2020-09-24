# Azure OSDU R3 - How to Set Up Environment Variables

This page describes how to set up environment variables when deploying this infrastructure. We use [direnv](https://direnv.net/) to source our environment variables. You will create a .envrc file to store these variables: `touch <project_root>/infra/templates/osdu-r3-resources/.envrc`. This file will store the information Terraform needs to deploy the infrastructure and you will fill it out as you complete the instructions in this repo. Here is the template you will be using for this deployment:
```bash
# .envrc in <project_root>/infra/templates/osdu-r3-resources/

# Adjust these as needed
    export BUILD_BUILDID=1
    export GO_VERSION=1.12.5
    export TF_VERSION=0.12.4

# Subscription Info
    export ARM_SUBSCRIPTION_ID="<you will fill this in>"
# Terraform Service Principal Info
    export ARM_TENANT_ID="<you will fill this in>"
    export ARM_CLIENT_ID="<you will fill this in>"
    export ARM_CLIENT_SECRET="<you will fill this in>"
# Terraform State Storage Info
    export TF_VAR_resource_group_location="useast" # this is just a default value, change it if you'd like
    export TF_VAR_remote_state_account="osdutstate" # this is just a default value, change it if you'd like
    export TF_VAR_remote_state_container="tstate" # this is just a default value, change it if you'd like
    export ARM_ACCESS_KEY="<you will fill this in>"
# Instance Variables for Terraform Deployments
    export TF_VAR_ssh_public_key_file=/home/$USER/.ssh/node-ssh-key.pub
    export TF_VAR_gitops_ssh_key_file=/home/$USER/.ssh/gitops-ssh-key
    export TF_VAR_common_resources_workspace_name="${USER}-cr" # only change this is you name you workspace to something other than what the instructions say
    export TF_VAR_data_resources_workspace_name="${USER}-dr" # only change this is you name you workspace to something other than what the instructions say
    export TF_VAR_cosmosdb_replica_location="centralus" # this is just a default value, change it if you'd like
    export TF_VAR_elasticsearch_endpoint="<you will fill this in>"
    export TF_VAR_elasticsearch_username="<you will fill this in>"
    export TF_VAR_elasticsearch_password="<you will fill this in>"
    export TF_VAR_gitops_ssh_url="<you will fill this in>" # you can find this in the Flux repo you create, it will look something like git@github.com:Azure/osdu-infrastructure.git
    export TF_VAR_gitops_branch="master" # only change if you want Flux to watch a branch other than master
```
Note: remember to "direnv allow" into a bash terminal whenever these values change so that they are properly updated.