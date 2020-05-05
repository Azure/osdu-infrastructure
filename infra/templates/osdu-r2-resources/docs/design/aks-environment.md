# Deploying OSDU R2 services with Kubernetes + Elastic Cloud

v0.1 - 2/6/2020

## Introduction

Some of Cobalt’s enterprise customers have a small number of microservices they'd like to deploy and host on [AKS](https://docs.microsoft.com/en-us/azure/aks/). Geospatial documents are indexed in Elastic Search to accomodate bounding box and radius distance querying scenarios. This template provisions an instance of an fully managed PaaS Elasticsearch hosted in [EC](https://www.elastic.co/cloud/).

This document outlines how Cobalt can be extended to meet the use cases of these customers. The intended audience of this document is the development and product teams working on Cobalt and related projects.

## In Scope

- Identify deployment topology needed by the customer
- Identify key Terraform templates needed for deployment
- Identify key Terraform modules needed for deployment
- Identify gaps in Terraform provider templates
- [Bedrock](https://github.com/microsoft/bedrock) integration
- How existing storage services like Elastic Cloud and Cosmos can be imported to reduce azure subscription incurred costs

## Out of scope

- External customer sign-off
- Template (Terraform, ARM) implementation
- VNET Integration
- Traffic Manager Integration
- APIM integration
- Istio integration

## Key Terms
- **RG**: Abbreviation for “Resource Group”
- **Sub**: Abbreviation for “Subscription”
- **Persona**: An archetype of a Cobalt customer
- **Stage**: An application deployment stage (dev, qa, pre-prod, prod, etc...)
- **Region**: A location in which an application is deployed


## Customers
- **Admin**: This persona represents an administrator of Azure. This persona does not implement the line of business applications but will help other teams deliver them.
- **App Developer Team**: This persona is responsible for creating and maintaining the line of business applications

## Deployment Topology

This graphic shows the targeted deployment topology needed by our enterprise customers. The deployment is deployed to a single tenant and subscription. The resources are partitioned to align with the different personas within the customer.

![Deployment Topology](./.design_images/aks_deployment_topology.jpg "Deployment Topology")

## Template Topology

The graphic below outlines the topology of the terraform templates that will deploy the topology called out above.

![Template Topology](./.design_images/aks_template_topology.jpg "Template Topology")

## Terraform Template Environment Dependencies

```
└── environments
    ├── data_sources
    │   ├── backend.tf
    │   ├── commons.tf
    │   ├── outputs.tf
    │   ├── storage.tf
    │   ├── terraform.tfvars
    │   └── variables.tf
    ├── image_registry
    │   ├── backend.tf
    │   ├── outputs.tf
    │   ├── registry.tf
    │   ├── terraform.tfvars
    │   └── variables.tf
```
### data_sources

The [container_cluster](../../environments/container_cluster/variables.tf) environment relies on the resources from the [data_sources](../../environments/data_sources/variables.tf) environment as the data storage reference for blob storage, cosmos and REDIS. 

### image_registry

The [container_cluster](../../environments/container_cluster/variables.tf) environment relies on the resources from the [image_registry](../../environments/image_registry/variables.tf) environment to source all docker images deployed to the AKS cluster.

## Template Inputs
Supported arguments for the aks environment are available in [variables.tf](../../environments/container_cluster/variables.tf).

### Credential Management

The AKS cluster will be configured with a `SystemAssigned` identity to enable MSI integration with resources like Service Bus, ADLS Gen 2 and Keyvault. 

MSI is enabled through the [identity block](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html#type-2) of the `azurerm_kubernetes_cluster` Terraform provider.

The AKS MI integration feature is in Preview. You can reference the AKS MI [docs](https://docs.microsoft.com/en-us/azure/aks/use-managed-identity) for manual setup instructions.

## Security

Managed Identity is integrated with AKS only in public preview mode. 

Here is an overview of the security for the deployment strategy and templates discussed above:

- **Role Assignments**: The service principal running the deployment will have to be an owner in the target subscription and granted admin consent to the `Application.ReadWrite.OwnedBy` role in Microsoft Graph. This template creates a new service principal that will be available for application developer team(s) to administer the provisioned Azure resources. The following role assignments will be made to that service principal:
  - Contributor access to AKS & App Insights in the first Resource Group


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