# Problem Statement
This document is intended to survey the existing code base to understand how service to service auth is done today, what the shortcomings are, and what changes we should make in order to reduce technical debt in this area and make the services overall more secure.

**In Scope**
 - Service to service auth

**Out of Scope**
 - OSDU level entitlements and auth
 - Non MSI key rotation (i.e., rotating keys in KeyVault) 


# What are the strategies used for authentication and authorization in the existing solution? What are the shortcomings, if any?

 **App Service & Azure Function -> Cosmos, Blob Storage, Message Bus**
 - Access keys for these services are rendered from environment variables -- defined at run-time through app settings -- and injected into the code base by means of Spring properties. Cosmos and Message bus are configured at run-time using [Azure Spring Boot Starter Kits](https://github.com/microsoft/azure-spring-boot). Blob Storage is configured at run-time using hand-rolled code which pulls credentials from the environment.
 - Shortcomings
   - This strategy does not support key rotation without redeploying the application properties
   - This strategy makes the deployment more complicated because you need to know the secrets at deployment time. This increases the chance of secrets accidentally being logged. It also makes manual error likely as you need to copy and paste from the portal to an AzDO variable library, or build an automated solution to do this.
     - Anybody who can see the app settings can see the credentials to any of the dependent services

 **App Service & Azure Function -> Elastic Search**
 - Credentials are stored in Cosmos and pulled at run-time to configure Elastic Search. This is being further investigated in https://dev.azure.com/slb-des-ext-collaboration/open-data-ecosystem/_workitems/edit/625
 - Shortcomings: Anybody with access to cosmos can see these keys; this also adds an additional layer of complexity because the keys need to be stored in Cosmos but there is no automated way to do or manage this.

# What should be the strategy for authentication and authorization between managed Azure services? can MI be used?
[Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) are the preferred approach for authenticating between managed services in Azure. The major benefit of this approach is that access credentials need not be passed around between developers nor configured as environment variables during deployments. This solution also handles any behind-the-scene key rotations that need to happen without any additional effort from the development team.

[azure-sdk-for-java](https://github.com/Azure/azure-sdk-for-java/tree/master/sdk/identity/azure-identity) can be used to authenticate to Azure services using MSI.

One challenge when using Managed Identities is that a local development environment does not support MI. We need a way to fallback to environment driven authentication. This is solved by using [DefaultAzureCredential](https://github.com/Azure/azure-sdk-for-java/tree/master/sdk/identity/azure-identity#authenticating-with-defaultazurecredential).

Here is how this would work with (for demonstration purposes) a KeyVault client:
```java
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.identity.DefaultAzureCredentialBuilder;

// Omitting all use of Spring Dependency Injection...
class ExampleClass {
    void ExampleFunction() {
        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();
        SecretClient client = new SecretClientBuilder()
            .vaultUrl("https://{YOUR_VAULT_NAME}.vault.azure.net")
            .credential(defaultCredential)
            .buildClient();
    }
}
```

**Note**: This will change how we instantiate our service clients. The current usage of the Spring Starter Kits does not support MSI so we can remove these dependencies in favor of the singular Java SDK for Azure!

Based on the [availability of MI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities) it will be possible to leverage MI to authenticate the following connections:
 - App Service & Azure Function -> Blob Storage
 - App Service & Azure Function -> Service Bus
 - App Service & Azure Function -> Key Vault

Examples of how to do this can be [found here](https://github.com/Azure/azure-sdk-for-java/tree/master/sdk/identity/azure-identity#credentials).

Unfortunately MI is not supported for Cosmos, Elastic Search and other services. Credentials for these services should be stored in KeyVault and retrieved at run-time for the following reasons:
 - KeyVault is the defacto data store for sensitive information like credentials
 - KeyVault keys can be changed without needing to redeploy application code or modify things like app settings.

These credentials should be provisioned as part of the template being designed in https://dev.azure.com/slb-des-ext-collaboration/open-data-ecosystem/_workitems/edit/617
 


# What should be the strategy for authentication and authorization between managed Azure services and Elastic Search?
The Elastic SDK for Java enables for configuration of a [Credentials](https://hc.apache.org/httpcomponents-client-4.5.x/httpclient/apidocs/org/apache/http/auth/Credentials.html) that can be used to configure request credentials on a per-request basis. The proposal is to leverage this built-in solution by implementing Credentials backed by keyVault. This can be wired up to the Elastic client as show in [this example](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/current/_basic_authentication.html).

Considerations:
 - Why not construct the auth header manually like we do today?
   - This is already implemented in the OSS community and is officially recommended as the correct approach by Elastic.
 - How can we prevent somebody from reverse engineering the credentials by looking at the auth token?
   - We should be using HTTPS for Elastic to prevent this as a possibility.
 - Is there a reason to cache the credentials returned from KeyVault?
   - There at least 2 reasons we might want to cache
     - Avoid successive calls to KeyVault for subsequent requests
     - Handle the case where the Elastic Search credentials rotate in KeyVault.
     - Both of these scenarios can be easily solved by using a simple in-memory cache with a reasonable (1 minute? 10 minutes?) TTL. A natural option when using Spring is to leverage the [@Cacheable](https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/cache/annotation/Cacheable.html) annotation.
       - **Note**: A remote cache like Redis should be avoided as to not leak security credentials beyond the in-memory processing of the host
     - **Note: caching can be deferred if necessary as it is purely an optimization and should only yield benefits under heavy service load.**


# Proposal in image form
![auth](.design_images/auth.png)


# Testing with MI
 By migrating things like (1) MI configuration and (2) secrets living in KV, we can start to test that we've done the right thing by using two approaches:
 - Validate ACL through automated infrastructure testing, similar to the strategy used in Cobalt. Unit or integration tests can be used depending on the use-case
 - Validate run-time behavior through integration testing that validates access to all dependent services

# How does OSDU Multi-Tenancy impact service auth?
OSDU has a concept of multi-tenancy that needs to be taken into account when we re-think our approach to service to service auth. In this project, the OSDU Tenant is sometimes used to determine which service endpoint a request should be routed to.
 - Example: OSDU Tenant is used to select the correct Elastic Search cluster to use for indexing
- Example: OSDU Tenant is used to select correct repository for storing legal tags

So, then, how does this impact service auth for this project? There are two cases:
- **Auth not leveraging MI (credentials in KeyVault)**: Similar to the approach used today where credentials are in Cosmos, we will need to store the metadata for each tenant-specific service in keyvault. Then, at service runtime, we will need to determine which keys to use to pull the relevant service metadata. Example:
```
KeyVault Key        --> Sample KeyVault Value
tenant1.es-endpoint --> https://superawesome.elastic.t1.com:443/
tenant1.es-username --> my-fake-user-1
tenant1.es-password --> my-fake-passwd-1
tenant2.es-endpoint --> https://superawesome.elastic.t2.com:443/
tenant2.es-username --> my-fake-user-2
tenant2.es-password --> my-fake-passwd-2
```
 - **Auth leveraging MI**: This can be easily configured in the infrastructure templates being designed in https://dev.azure.com/slb-des-ext-collaboration/open-data-ecosystem/_workitems/edit/617
 


**Appendix**:
Impact of multi-tenancy in each of the core services:

`os-search`: Tenant is used to select the correct Elastic Search endpoint & corresponding credentials.
 - The Azure configuration in Cosmos always points to the same ES configuration. This appears to not be the intention of the code and is a configuration issue

`os-indexer`: Tenant is used to select the correct Elastic Search endpoint & corresponding credentials.
- The Azure configuration in Cosmos always points to the same ES configuration. This appears to not be the intention of the code and is a configuration issue

`os-legal`: Tenant is used to select the correct repository for storing legal tags.
- The azure implementation always uses a single repository but this appears to not be the intended use case

`os-indexer-queue`: Tenant is pulled from Service Bus message and added as a header in the HTTP call to os-indexer.
- Tenant has no bearing on Auth

`os-entitlements-azure`: Tenant is used to query user.
- Tenant has no bearing on Auth

`os-storage`: The Record APIs check for a valid Tenant ID before allowing any modifications to Blob Storage or Cosmos.

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