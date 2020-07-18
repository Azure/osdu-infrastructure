# OSDU GitOps Design

## Problem Statement

The OSDU needs to deploy containerized services into a production-ready kubernetes environment and ensure consistent, durable deployments across multiple clusters. In the initially targeted single tenant model, each customer could operate many, identially configured OSDU environments.

## In Scope

- GitOps for managing desired application deployment state
- Administrator Workflows to configure Azure Infrastructure
- Developer Workflows to deploy services and service updates

## Out of Scope

- Deployments to Cloud Providers other than Azure
- Multiple, seperated environments for dev, test and production.
- Cloud Native Observability beyond out-of-the-box AKS / Azure Monitor capabilities

## Solution Approaches

The following two solution approached were considered:

### AKS + Azure DevOps pipelines

*Pro:*

- Flexibility on configuration, add-ons, etc.

*Con:*

- Starting from scratch, instead of leveraging re-usable assets
- No change logs
- No durabge configuraiton store
- Scale out model to create multiple clusters

### Light Weight GitOps Process

*Pro:*

- Easy to get started with Flux setup from bedrock
- Approachable complexity and learning curve, leveraing knowledge of git and kubernetes manifests.
- GitOps model with durable desired state store using AzDO repos

*Con:*

- No library of pre-built solution stacks.
- Initially manual update of manifest versions.
- No built-in support for advanced scenarios, e.g. canary deployments and rings.

### Fully Automated Bedrock

*Pro:*

- Existing "Stacks", i.e. preconfigured packages to deploy complate environments into cluster
- Full GitOps model with durable desired state store using AzDO repos
- Deployments described using Higher Level application & deployment abstractions simplify operations of many identical clusters

*Con:*

- Early in its lfecycle
  - raw, incomplete documentation,
  - few proof points
- Pre-chosen stack (AKS + helm + terraform + custom HLD)
- Complex environment with custom file formats and assets distributed across multiple repos.

## Recommendation

The Light Weight GitOps process is well suited to educate on the benefits of a GitOps flow. It also keeps the workflow simple and streamlined. Therefore the light weight option is an ideal starting point.

Once the customer understand GitOps and is investigating approaches for multi-tenancy and advanced deplyment techniques, a full bedrock deployment leveraging HLDs for service descriptions and full automation of deployments is recommended.

This recommendation allows bedrock to gather feedback from other on-going deployments and mature its documentation. Stability is expected to improve greatly over the next 4 weeks. Once bedrock is deployed, OSDU can easily take advantage of advanced capabilities, e.g. introspection and canary deployments that are currently out of scope.

## Process

### Personas

1. Infrastructure / GitOps Admin: Provisions and manages infrastructure repo and cloud infrastructure.
1. DevOps developer: Develops application code and deployment assets.
1. Application Admin: Reviews and approves version readiness for deployment.

### Automated Infrastructure / GitOps Admin Process to deploy bedrock clusters for OSDU

The GitOps admin uses a combination of bedrock tools, the Azure CLI and terraform to stand up the infrastructure.

1. GitOps Admin creates and initializes Cluster Manifest Repo.
1. GitOps Admin generates PAT for Flux GitOps process to access Cluster Manifest Repo.
1. GitOps Admin creates cluster definition from an existing Terraform template.
1. GitOps Admin Creates (or re-uses) AKS Service Principal.
1. GitOps Admin creates Azure Container Registry (if needed).
1. GitOps Admin creates terraform templates from cluster definition by running spk infra generate.
1. GitOps Admin creates AKS cluster from generated terraform templates.

The following diagram illustrates this workflow.
![Infrastructure Provisioning Workflow](images/gitops2-14-Infra%20Setup.png)

### Light Weight Flow

#### Preparing GitOps for a new service

1. Developer initializes Application Repo

![Service GitOps Onboarding Workflow](images/gitops2-14-Simple%20Initial%20Bedrock%20Setup.png)

#### Developer Process Configuring OSDU Service to deploy to bedrock clusters

At a high level, the steps for an bedrock application developer to make a deployment change, i.e. deploying a new application or deploying a new version of an existing application closely follow  the model for committing a code change to a source code repository.

1. Developer commits code to Application Repo and, as needed, kubernetes deployment manifests to the Manifest Repo.
1. Merge triggers Build Pipeline builds Application container, updates container version and publishes container to Azure Container Registry. (`build` stage).
1. Build Pipeline creates PR against HLD Repo to update HLD and helm chart with new container version (`hld_update` stage).
1. PR triggers Manifest Generation Pipeline to run fabrikate to generate Kubernetes deployment manifests, creates PR against Manifest repo.
1. Flux polls for changes in the Manifest repo and detects changes to desired state.
1. Flux initiates changes to cluster deployment (kubectl apply).

![Service Deployment Workflow](images/gitops2-14-Simple%20Update.png)

### Advanced Flow

#### DevOps provisioning for GitOps operations

The GitOps approach to managing deployment state requires AzDO repos and pipelines. Those are infrastructure specific, not application specific.

1. GitOps Admin creates Manifest Repo.
1. GitOps Admin creates HLD repo with initial component.yaml.
1. Admin creates Manifest pipeline.

![DevOps Provisioning Workflow](images/gitops2-14-Detailed%20Initial%20Bedrock%20Repo%20Setup.png)

#### Preparing GitOps for a new service

1. Developer initializes Application Repo and Variable Group.
1. Developer adds service to bedrock.yaml.
1. Developer creates Application Helm Chart Repo.
1. Developer adds Build Pipeline configured to publish to ACR and update HLD Repo.
1. Developer updates HLD component yaml.

![Service GitOps Onboarding Workflow](images/gitops2-14-Detailed%20Onboard%20New%20Service.png)

#### Developer Process Configuring OSDU Service to deploy to bedrock clusters

At a high level, the steps for an bedrock application developer to make a deployment change, i.e. deploying a new application or deploying a new version of an existing application closely follow  the model for committing a code change to a source code repository.

1. Developer commits code to Application Repo and, as needed, `bedrock.yaml`, helm chart to Application Helm Chart Repo.
1. Merge triggers Build Pipeline builds Application container, updates container version in helm chart and publishes container to Azure Container Registry. (`build` stage).
1. Build Pipeline creates PR against HLD Repo to update HLD and helm chart with new container version (`hld_update` stage).
1. PR triggers Manifest Generation Pipeline to run fabrikate to generate Kubernetes deployment manifests, creates PR against Manifest repo.
1. Flux polls for changes in the Manifest repo and detects changes to desired state.
1. Flux initiates changes to cluster deployment (kubectl apply).

![Service Deployment Workflow](images/gitops2-14-Detailed%20Update.png)

## Open Investigations

1. How does OSDU Multi-Tenancy impact GitOps Design?
OSDU has a concept of multi-tenancy that needs to be taken into account when we re-think our approach to cluster provisining and service deployment.

2. How does the design extend to individual clusters for dev, test and prod?
OSDU wants to follow a traditional approach separating dev, test and production environments.

3. How can the version update in the Light Weight Flow be automated? 

4. How should we approach automated approval of auto-generated PRs to HLD and manifest repos?
Will auto-approve meet the customer's requirements for quality control?
Can we implement automated approval by creating PRs with auto-complete or via Service Hooks?


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