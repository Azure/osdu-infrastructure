## Service deployment into Azure via Azure DevOps

This document describes how to deploy an OSDU service to Azure by taking advantage of the shared build and release templates that can be re-used across services.

### Prerequisites
 - If you have not yet deployed the infrastructure for the service, please follow the onboarding steps in the appropriate infrastructure template folder. Be sure to select the appropriate reference architecture for your use case.

### Step 1: Configure the devops pipelines
Services will typically leverage the following common templates to configure their build and release stages:
 - `devops/service-pipelines/build-stage.yml`
 - `devops/service-pipelines/deploy-stages.yml`

This pipeline will live in the service repository. Here is what one such pipeline might look like:
```yaml
# Omitting PR and Trigger blocks...

variables:
  - group: 'Azure Common Secrets'
  - group: 'Azure - Common'
  - name: serviceName
    value: 'foo-service'

resources:
  repositories:
    - repository: infrastructure-templates
      type: git
      name: open-data-ecosystem/infrastructure-templates

stages:
  - template: devops/service-pipelines/build-stage.yml@infrastructure-templates
    parameters:
      copyFileContents: |
        pom.xml
        maven/settings.xml
        target/*.jar
      copyFileContentsToFlatten: ''
      mavenOptions: '--settings ./maven/settings.xml -DVSTS_FEED_TOKEN=$(VSTS_FEED_TOKEN)'
      serviceBase: ${{ variables.serviceName }}
      testingRootFolder: 'integration-tests'
  - template: devops/service-pipelines/deploy-stages.yml@infrastructure-templates
    parameters:
      serviceName: ${{ variables.serviceName }}
      testCoreMavenPomFile: 'testing/legal-test-core/pom.xml'
      testCoreMavenOptions: '--settings $(System.DefaultWorkingDirectory)/drop/deploy/testing/maven/settings.xml'
      providers:
        -  name: Azure
           # Merges into Master
           ${{ if eq(variables['Build.SourceBranchName'], 'master') }}:
             environments: ['devint', 'qa', 'prod']
           # PR updates / creations
           ${{ if ne(variables['Build.SourceBranchName'], 'master') }}:
             environments: ['devint']
```

There are some key areas that are worthwhile to understand, as it will impact the variable groups that are required when defining the variable groups:
 - Stanza which defines the `environments`. This controls where the application will be deployed to. It should match the environments configured in the infrastructure pipeline. In the example shown here, the environments deployed will depend on whether or not the build has been triggered from the `master` branch. This enables PR builds to deploy only to `devint`.
 - Stanza which defines the `serviceName`. This controls the name of the service. It should be unique for each service being deployed.

This pipeline will need to be configured in Azure DevOps. The instructions to do this can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops#define-pipelines-using-yaml-syntax).


### Step 2: Configure the Azure DevOps Variable Groups
The following table describes the variable groups required to support this service deployment:

`Azure Common Secrets`

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `aad-entitlement-integration-test-app-client-id` | `********` | Service identity with full entitlements to data | yes | keyvault |
| `aad-entitlement-integration-test-app-client-secret` | `********` | Secret for `aad-entitlement-integration-test-app-client-id` | yes | keyvault |
| `vsts-feed-token` | `********` | Personal Access Token that grants access to the maven repository` | yes | keyvault |
| `aad-no-data-access-tester-client-id` | `********` | Service identity with no entitlements to data | yes | keyvault |
| `aad-no-data-access-tester-secret` | `********` | Secret for `aad-no-data-access-tester-secret` | yes | keyvault |

`Azure - Common`

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `AGENT_POOL` | `Hosted Ubuntu 1604` | Agent on which to run release | no | ADO |
| `AZURE_AD_APP_RESOURCE_ID` | `$(aad-client-id)` | see `aad-client-id` | yes | ADO |
| `AZURE_AD_OTHER_APP_RESOURCE_ID` | `$(aad-entitlement-integration-test-app-client-id)` | AD Application ID used for negative testing | yes | ADO |
| `AZURE_DEPLOY_APPSERVICE_PLAN` | `$(ENVIRONMENT_RG_PREFIX)-$(PREFIX_BASE)-sp` | App Service Plan in which App Service lives | no | ADO |
| `AZURE_DEPLOY_CLIENT_ID` | `********` | Client ID used to deploy to Azure | yes | ADO |
| `AZURE_DEPLOY_CLIENT_SECRET` | `********` | Client secret for `AZURE_DEPLOY_CLIENT_ID` | yes | ADO |
| `AZURE_DEPLOY_RESOURCE_GROUP` | `$(ENVIRONMENT_RG_PREFIX)-$(PREFIX_BASE)-app-rg` | Resource group in which App Service Plan lives | no | ADO |
| `AZURE_DEPLOY_TENANT` | `********` | Tenant linked to subscription | yes | ADO |
| `AZURE_ENTITLEMENTS_SERVICE_NAME` | `$(ENVIRONMENT_SERVICE_PREFIX)-entitlements` | Name of App Service for entitlements | no | ADO |
| `AZURE_INDEXER_SERVICE_NAME` | `$(ENVIRONMENT_SERVICE_PREFIX)-indexer` | Name of App Service for indexer | no | ADO |
| `AZURE_LEGAL_SERVICE_NAME` | `$(ENVIRONMENT_SERVICE_PREFIX)-legal` | Name of App Service for legal | no | ADO |
| `AZURE_LEGAL_SERVICEBUS` | `$(sb-connection)` | See `sb-connection` | yes | ADO |
| `AZURE_LEGAL_TOPICNAME` | `legaltags` | Legal topic name | no | ADO |
| `AZURE_SEARCH_SERVICE_NAME` | `$(ENVIRONMENT_SERVICE_PREFIX)-search` | Name of App Service for search | no | ADO |
| `AZURE_STORAGE_ACCOUNT` | `$(ENVIRONMENT_STORAGE_PREFIX)sa` | Storage account name | no | ADO |
| `AZURE_STORAGE_SERVICE_NAME` | `$(ENVIRONMENT_SERVICE_PREFIX)-storage` | Name of App Service for storage | no | ADO |
| `AZURE_TESTER_SERVICEPRINCIPAL_SECRET` | `$(app-dev-sp-password)` | See `app-dev-sp-password` | yes | ADO |
| `CONTAINER_REGISTRY_NAME` | `$(ENVIRONMENT_STORAGE_PREFIX)cr` | ACR name | no | ADO |
| `DEPLOY_ENV` | `empty` | Deployment environment | no | ADO |
| `DOMAIN` | `contoso.com` | Domain name | no | ADO |
| `ENTITLEMENT_URL` | `https://$(AZURE_ENTITLEMENTS_SERVICE_NAME).azurewebsites.net/` | Entitlements endpoint | no | ADO |
| `EXPIRED_TOKEN` | `********` | An expired JWT token | yes | ADO |
| `FUNCTION_APP_NAME` | `$(ENVIRONMENT_BASE_NAME_21)-enque` | Name of App Service for enqueue function | no | ADO |
| `INTEGRATION_TESTER` | `$(app-dev-sp-username)` | See `app-dev-sp-username` | yes | ADO |
| `LEGAL_URL` | `https://$(AZURE_LEGAL_SERVICE_NAME).azurewebsites.net/` | Endpoint for legal service | no | ADO |
| `MY_TENANT` | `opendes` | OSDU tenant used for testing | no | ADO |
| `NO_DATA_ACCESS_TESTER` | `$(aad-no-data-access-tester-client-id)` | See `aad-no-data-access-tester-client-id` | yes | ADO |
| `NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET` | `$(aad-no-data-access-tester-secret)` | See `aad-no-data-access-tester-secret` | yes | ADO |
| `PREFIX_BASE` | `osdu-r2` | . | no | ADO |
| `PUBSUB_TOKEN` | `az` | . | no | ADO |
| `RESOURCE_GROUP_NAME` | `$(ENVIRONMENT_RG_PREFIX)-$(PREFIX_BASE)-app-rg` | Resource group for deployments | no | ADO |
| `SEARCH_URL` | `https://$(AZURE_SEARCH_SERVICE_NAME).azurewebsites.net/` | Endpoint for search service | no | ADO |
| `STORAGE_URL` | `https://$(AZURE_STORAGE_SERVICE_NAME).azurewebsites.net/` | Endpoint of storage service | no | ADO |
| `VSTS_FEED_TOKEN` | `$(vsts-feed-token)` | See `vsts-feed-token` | yes | ADO |
| `SERVICE_CONNECTION_NAME` | ex `cobalt-service-principal` | Default service connection name for deployment | no | ADO |

`Azure Target Env Secrets - $ENV`
> `$ENV` is `devint`, `qa`, `prod`, etc...

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `aad-client-id` | `********` | Client ID of AD Application created | yes | keyvault created by infrastructure deployment for the stage |
| `app-dev-sp-password` | `********` | Client ID secret of service principal provisioned for application developers | yes | keyvault created by infrastructure deployment for stage |
| `app-dev-sp-username` | `********` | Client ID of service principal provisioned for application developers | yes | keyvault created by infrastructure deployment for stage |
| `appinsights-key` | `********` | Key for app insights created | yes | keyvault created by infrastructure deployment for stage |
| `cosmos-connection` | `********` | Connection string for cosmos account created | yes | keyvault created by infrastructure deployment for stage |
| `cosmos-endpoint` | `********` | Endpoint for cosmos account created | yes | keyvault created by infrastructure deployment for stage |
| `cosmos-primary-key` | `********` | Primary key for cosmos account created | yes | keyvault created by infrastructure deployment for stage |
| `entitlement-key` | `********` | Entitlements service key | yes | keyvault created by infrastructure deployment for stage |
| `sb-connection` | `********` | Connection string for service bus created | yes | keyvault created by infrastructure deployment for stage |
| `storage-account-key` | `********` | Key for storage account created | yes | keyvault created by infrastructure deployment for stage |
| `elastic-endpoint` | `********` | Endpoint of elasticsearch cluster created | yes | keyvault created by infrastructure deployment for stage |
| `elastic-password` | `********` | Password for elasticsearch cluster created | yes | keyvault created by infrastructure deployment for stage |
| `elastic-username` | `********` | Username for elasticsearch cluster created | yes | keyvault created by infrastructure deployment for stage |

`Azure Target Env - $ENV`
> `$ENV` is `devint`, `qa`, `prod`, etc...

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `ENVIRONMENT_BASE_NAME_21` | ex: `devint-erisc-5vjyftn2` | Base resource name | no | ADO - driven from the output of `terraform apply` |
| `ENVIRONMENT_RG_PREFIX` | ex: `devint-erisch-5vjyftn2` | Resource group prefix | no | ADO - driven from the output of `terraform apply` |
| `ENVIRONMENT_SERVICE_PREFIX` | `$(ENVIRONMENT_BASE_NAME_21)-au` | Service prefix | no | ADO - driven from the output of `terraform apply` |
| `ENVIRONMENT_STORAGE_PREFIX` | ex: `devinterisc5vjyftn2` | Storage account prefix | no | ADO - driven from the output of `terraform apply` |
| `AZURE_DEPLOY_SUBSCRIPTION` | `********` | Subscription to deploy to | yes | ADO |
| `SERVICE_CONNECTION_NAME` | ex `cobalt-service-principal` | Service connection name for deployment | no | ADO |

`Azure Service Release - $SERVICE`
> `$SERVICE` is `legal`, `storage`, etc...
> Note: the configuration values here will change based on the service being deployed. Read them carefully!

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `MAVEN_DEPLOY_GOALS` | ex `azure-webapp:deploy` | Maven goal to deploy application | no | ADO |
| `MAVEN_DEPLOY_OPTIONS` | ex `--settings $(System.DefaultWorkingDirectory)/drop/provider/legal-azure/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_LEGAL_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION)` | Maven options for deployment goal | no | ADO |
| `MAVEN_DEPLOY_POM_FILE_PATH` | ex `drop/provider/legal-azure/pom.xml` | Path to `pom.xml` that defines the deploy step | no | ADO |
| `MAVEN_INTEGRATION_TEST_OPTIONS` | ex `-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DHOST_URL=$(LEGAL_URL) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_LEGAL_STORAGE_ACCOUNT=$(AZURE_STORAGE_ACCOUNT) -DAZURE_LEGAL_STORAGE_KEY=$(storage-account-key) -DAZURE_LEGAL_SERVICEBUS=$(AZURE_LEGAL_SERVICEBUS) -DAZURE_LEGAL_TOPICNAME=$(AZURE_LEGAL_TOPICNAME)` | Maven option for integration test | no | ADO |
| `MAVEN_INTEGRATION_TEST_POM_FILE_PATH` | ex `drop/deploy/testing/legal-test-azure/pom.xml` | Path to `pom.xml` that runs integration tests | no | ADO |
| `SERVICE_RESOURCE_NAME` | ex: `$(AZURE_LEGAL_SERVICE_NAME)` | Name of service | no | ADO |

### Step 3: Configure test data for integration tests

The following data will need to be seeded in CosmosDB in order for the integration tests to run:

| Cosmos Account | Cosmos Database | Cosmos Collection | Document | Reason | Notes |
| ---            | ---             | ---               | ---      | --- |---   |
| *stage-specific* | `dev-osdu-r2-db` | `TenantInfo` | `./integration-test-data/tenant_info_1.json` | Entitlements Service Integration Tests | Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `TenantInfo` | `./integration-test-data/tenant_info_2.json` | Entitlements Service Integration Tests  | Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `UserInfo` | `./integration-test-data/user_info_1.json` | Entitlements Service Integration Tests  | Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `UserInfo` | `./integration-test-data/user_info_2.json` | Storage Service Integration Tests  | Replace `$NO_DATA_SERVICE_PRINCIPAL_ID` with the value of `NO_DATA_ACCESS_TESTER` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `LegalTag` | `./integration-test-data/legal_tag_1.json` | Legal Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `LegalTag` | `./integration-test-data/legal_tag_2.json` | Legal Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `LegalTag` | `./integration-test-data/legal_tag_3.json` | Legal Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_1.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_2.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_3.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_4.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_5.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_6.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_7.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_8.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_9.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_10.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |
| *stage-specific* | `dev-osdu-r2-db` | `StorageSchema` | `./integration-test-data/storage_schema_11.json` | Storage Service Integration Tests  | Replace `$TENANT` with the value of `MY_TENANT` from the variable groups. Replace `$SERVICE_PRINCIPAL_ID` with the value of `app-dev-sp-username` from the variable groups |

### Step 4: Deploy the services

The final step in the process is to execute the deployment pipelines. You will need to bring the services up in the following order. This order is driven by dependencies within the services themselves:

 - `os-entitlements`
 - `os-legal`
 - `os-storage`
 - `os-search`
 - `os-indexer-enqueue`
 - `os-indexer`
