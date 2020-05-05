# Provisioning Elasticsearch with Terraform

## What are the options?

There are a few different flavors of Elasticsearch that can be considered for this project. They are summarized in the table below:

| Product | Managed Hosting | Hosted on | Management plane API support |
| --- | --- | --- | --- |
| Elasticsearch Azure Marketplace Solution | No | Azure | None |
| Elastic  Cloud Enterprise (ECE) | No | Kubernetes, VMs, on-prem servers | GA |
| Elasticsearch Service | Yes | AWS, GCP, Azure | Private Preview |


The ideal solution for infrastructure automation is to leverage an offering with managed hosting and stable management plane APIs. However, there is no solution that exists today to satisfy those needs.

The key R2 goal with regards to Elasticsearch is to enable repeatable deployments across different stages. It is not to support production workloads with low operational overhead. Therefore, the existence of stable management plane APIs becomes a differentiating factor between the offerings.

## The proposal

The proposal is to leverage ECE management plane APIs until we are able to know more about the offerings and release timeline of the APIs provided by *Elasticsearch Service*. This enables delivery of R2 goals.

### Risks

The risk of choosing ECE is expected to be minimal, but it does exist and is worth calling out.

We do not know what the private preview APIs look like for *Elasticsearch Service*. However, there is good reason to believe that they are very similar to the ECE APIs because ECE claims to be a self-hosted version of *Elasticsearch Service*. If the APIs are similar, then it is reasonable to expect that migrating to *Elasticsearch Service* will be a minor effort once the APIs become available to us.


### Notable Callouts

**Resource Isolation**

We need feedback from Elastic to understand how to deploy management plane APIs for our development cycles. Until we have more information (meeting pending) we can reasonably assume that we should have one set of management plane APIs provisioned per stage in order to achieve resource isolation.

These need not be stood up as a part of this template.

**Licensing**

In order to provision ECE, we should be leveraging a non-trial license, which requires a (non-free) license purchased through an enterprise account. Otherwise, we are subject to a 30 day trial period. More information [here](https://www.elastic.co/guide/en/elastic-stack-overview/current/license-management.html).

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