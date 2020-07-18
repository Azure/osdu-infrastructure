## Alerting and Monitoring Design Notes

In general, the goal of this effort has been to describe a way of using various Azure
(and 3rd party, as needed) tools and techniques to build systems that are highly observable
and easy to interpret. A typical problem with the use of too many logging and collection 
systems is that the don't produce valuable insight into the behavior of applications under
observation.

A typical need of an alerting and monitoring tool is to surface problems before they begin
to impact end-users, while not distracting operations personnel with false positives and other
unimportant alerts. Another way to think about the success of an alerting and monitoring 
solution is that it should alert operators about active outages before the deployers and operators (or IT/OPS
managers) get calls from angry customer end-users. 

Another aspect of these solutions is that they should help surface usage patterns
that would allow application product managers and developers to better understand how systems
are used, so that they can be optimized in ways that are know to be relevant to end-users. This
often takes the form of developing statistically relevant telemetry from a system while 
users are active, over a period of time. In our experience, using such telemetry to help identify
improper system usage (such as when an end-user application is written or changed in a way to only produces
unsuccessful transactions) is extremely valuable to maintainers of end-user applications, as well as
valuable to platform operators who want to defend the system against repeated, malformed transaction
loads.

In all cases, its important to capture signals and information from the system while it is
operating, and to enable informed reactions for system maintainers to take advantage of. 
Its also important to leverage and enrich the underlying application performance management 
(APM) data that's being generated. 

For example, with many of the service request transactions, 
Azure is tracking (via the App Insights SDK) an event data object that's unique to the transaction. 
Enriching that event is to add details to the event that the system probably can't resolve itself, e.g. 
business- or implementation-domain knowledge about a transaction, like user identity, tenant ID, 
legal tag, Such attributes are intended to aid searching, monitoring, or to diagnosis. 
See [this link](https://docs.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics) 
for more thoughts about adding custom attributes to what Azure tracks by default.

To help apply these concerns to the system, we've approached the problem from three distinct faces:
   * Identifying and instrumenting the system to produce meaningful business-level telemetry
   * Identifying and instrumenting the run-time systems are resources to produce operational telemetry
   * Capture telemetry in a universal, durable, searchable, and actionable manner.
    
In general, Azure natively produces a great deal of potential data sources for telemetry and 
operational aspects (think: request counts, timing information, disk utilization, CPU 
utilization HTTP error counts, standard output/error collection & correlation, etc). Upon this we're
recommending the employment of of Azure Insights SDK code it wrap business transactions, and
also to send & receive correlation IDs between resources that are provided by Azure as a 
managed service (Elastic Search/Cloud, for example).

Finally, this document focuses on the needs of the code and operations that are provided within 
the Azure OSDU Provider implementation. There are similar OSDU concerns for tracking, auditing, 
logging, etc. With the sole exception of collecting and centralizing logging that is produced
'above' the provider layer, isn't making suggestions or comments about the common code shared
across providers. 

For example, OSDU exposes some `correlation-id` attributes via the `DspHeader` 
logging facility, and Azure Monitor application Insights also exposes some correlation attributes 
used by that Azure facility, but these are distinct domains of concern, and the use of App Insights
isn't meant to impact how OSDU applications might use the `correlation-id` in DSP headers.

## Acceptance Criteria

### What types of scenarios do we need to monitor?

In general, there are a few kinds of scenarios that need to be monitored. 
Some of these are universal, across services, and some a specific to services.

For each service, we need to catalog interesting business-level failures, 
like authorization failures, CRUD counts, CRUD failures due to service problems, 
and CRUD failures due to business rule failure 
(e.g. expired legal tags are trying to be used). etc. 
We're recommending some examples, as follows, but more exhaustive ideas 
are warranted, along with a standing published approach towards adding 
more events, once the system is underway and usage patterns emerge:

#### Common across services
 * *Event:* Underlying dependent services are missing / unavailable.
 * *Event:* Authentication failures
     * Invalid JWT
     * Invalid login attempt. See [here](https://blogs.msdn.microsoft.com/samueld/2015/09/28/azure-ad-connect-health-top-users-with-failed-username-password-logins-for-adfs/)
for some excellent examples.
 * *Event:* Authorization/entitlement failures
     * At the "pre-filter" level
     * At the "data" level (where this can be known)
 * *Event enrichment:* Handle inbound & place outbound distributed tracing tokens, and Application Map requirements
 * *Event enrichment:* Adhere to OSDU logging, as needed, also be sure centralized logging (at the Azure level) is properly engaged
 * *Metric:* Returned counts
 * *Metric:* Request timing
 * All events and metrics need to be tracked by:
    * Endpoint (e.g. `GET /query/records`, `POST /query/records`)
    * `correlation-id`
    * `account-id`
    * `data-partition-id`
    * HTTP Response Code
 * All transactions will need to be instrumented to ensure that critical Azure App Insights distributed
 transaction attributes are preserved and passed along for inbound and outbound transaction (e.g. between
 Service Hub messages, calls to Elastic Search, CosmosDB, etc). _Most HTTP/S intra-service calls will
 automatically preserve these attributes, if App Insights SDK is properly installed and configured, for
 a given service._
 * All Java-based services will need to have the App Insights SDK for Java added as a Maven dependency, 
 and some configuration applied. There are Spring Boot-specific concerns. Instructions are laid out in the [Azure Monitor SDK for Java Getting Started guide.](https://docs.microsoft.com/en-us/azure/azure-monitor/app/java-get-started)
  
#### Search Service

Beyond the common examples listed above, we believe it will be helpful to track problems with query
language, so as to help spot applications and end-users that are submitting problematic queries, to
speed up remediation and help with RCA of those applications.
 
 * *Event:* Malformed query (for endpoints accepting query language, i.e. `POST /query`)

#### Entitlement Service

Beyond the common examples listed above, we believe it will be helpful to detect sudden changes in the
number of entitlements returned for subjects. For example, if some groups suddenly stop returning
hundreds of (expected) entitlements, this could signal a more general problem with how subject IDs
are presented to the servicec, or perhaps how they service is implemented. Also, having good metrics
on the typical volumes of entitlements by subject/query/etc, provider implementation can be tuned to
better suit performance goals for this service.

 * *Metric:* Return volume (record counts) by subject (i.e. user, group)

#### Storage Service

Beyond the common examples listed above, we believe it will be helpful to track some of the ways
that Storage Service transactions fail (even while the service is working perfectly) due to improper
payloads or expired or errant legal tags, ACLs, schema/kinds, and/or malformed payloads.

 * *Event:* PUT Storage w/ bad:
     * Expired or un-resolvable Legal tags
     * Un-resolvable ACLs (owner/viewer)
     * Un-resolvable Schemas 
     * Malformed payload
#### Legal Service

Beyond the common examples listed above, we believe it will be helpful to track queries against expired
or non-existent legal tags. Sudden load spikes for 'bad' legal tags may indicate a problem with how legal 
tags are being assessed (perhaps a problem with time keeping on service hosts) or even something 

 * *Event:* Fetch expired and non-existent tag

### What metrics or events should be emitted to support each monitoring scenario?

There are a set of 'out of the box' metrics that we're recommending, in addition to 
the business-focused examples listed above.

#### Azure CosmosDB

Please consult the [_Monitor CosmosDB Reference_](https://docs.microsoft.com/en-us/azure/cosmos-db/monitor-cosmos-db-reference)
for more detail about available metrics. _Note we aren't suggesting the use of Azure Preview capabilities
for CosmosDB._

| Metric |
|---------------------------------------------|
| Available Storage                           |
| Data Usage                                  |
| Document Count                              |
| Service Availability                        |
| Index + Data Storage Consumed               |
| Max consumed RU/second                      |
| Total Requests                              |

#### App Service Plan

| Metric |
|---------------------------------------------|
| CPU Time                                    |
| Avg Memory Working Set                      |
| Avg Response Time                           |
| Request in Application Queue                |
| Thread Count                                |
| Memory Percentage                           |
| Delete App Service Plan                     |

#### Service Bus

| Metric |
|---------------------------------------------|
| CPU                                         |
| Clount Active Message                       |
| Count Dead-Lettered Messages                |
| Count of Message                            |
| Size                                        |
| Successfile Requests                        |
| Throttled Requests                          |
| Server Errors                               |

#### Azure Cache for Redis

| Metric |
|---------------------------------------------|
| Redis Server Load                           |
| Operations per Second                       |
| Total Keys                                  |
| Cache Hits                                  |
| Cache Misses                                |
| Memory Usage                                |
| Network Bandwidth                           |
| CPU Usage                                   |

#### Storage Account

| Metric |
|---------------------------------------------|
| Transactions                                |
| Used Capacity                               |
| Blob Count                                  |
| Ingress                                     |
| Egress                                      |
| Succes E2E Latency                          |

#### App Services - Function App

| Metric |
|---------------------------------------------|
| Avaliability                                |
| CPU Time                                    |
| Avg Memory Working Set                      |
| Avg Response Time                           |
| Request in Application Queue                |
| Thread Count                                |
| Memory Percentage                           |
| Server Response Time                        |
| Failed Requests                             |

#### App Services - Web App

| Metric |
|---------------------------------------------|
| Http Server Errors                          |
| Http Response Code Counts (all)             |
| CPU Time                                    |
| Avg Memory Working Set                      |
| Avg Response Time                           |
| Request in Application Queue                |
| Thread Count                                |
| Memory Percentage                           |

##### A quick word about Service Limits: 

Without more information about SLAs and nominal 
request/data volumes for typical OSDU deployments, 
it's difficult to gauge any service limit problems. 
It's likely that the default limits will be workable 
for the immediate future. The Azure Monitor (this covers App Insights, too) 
are described in the [Azure Monitor Service Limits documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/service-limits).

### How can we alert on the in-scope scenarios?

We recommend funneling all alerting and notification through Azure Monitoring and 
App Insights. This will allow end-users to employ Azure alerting and notification 
capabilities, and/or PageDuty, etc. as desired by their business and operations teams.

### How can we measure the in scope scenarios in a way that can be alerted on?

I believe that this question/criteria is meant to ask how we'd test the 
monitoring/alerting, to be sure it is working. In previous engagements, 
we've employed application-level testing/diagnostic settings to inject 
errors in a non-production deployment that has alerting and monitoring 
fully enabled. A specific set of alerts is chosen for test, and then waits, 
pauses, and manually triggered exceptions are enabled which trigger the 
scenarios under test.  

## Implementation Detail

#### Alter the maven dependencies to include the App Insights SDK for Java

Per the instructions [here](https://docs.microsoft.com/en-us/azure/azure-monitor/app/java-get-started),
there are a few `xml` files to configure. The
instructions here should tackle most of the configuration changes, however
I recommend that any performing these changes also read that link to get
any latest changes needed by Azure and to better understand what's 
involved, here.

For Azure provider (service) jars, add a needed dependency which 
gives you metrics that track HTTP servlet request counts and 
response times, by automatically registering the Application 
Insights servlet filter at runtime:

```xml
<dependencies>
  <dependency>
    <groupId>com.microsoft.azure</groupId>
    <artifactId>applicationinsights-web-auto</artifactId>
    <version>2.5.0</version>
  </dependency>
</dependencies>
```

#### ApplicationInsights.xml

With the Application Insights for SDK on hand, it'll need to be configured, too, via
an `ApplicationInsights.xml` file (_note: we're leaving out the instrumentation key
from this file... the value for the key will be provided at runtime via the
environment variable `APPINSIGHTS_INSTRUMENTATIONKEY`_):

```xml
<?xml version="1.0" encoding="utf-8"?>
<ApplicationInsights xmlns="http://schemas.microsoft.com/ApplicationInsights/2013/Settings" schemaVersion="2014-05-30">

   <!-- HTTP request component (not required for bare API) -->
   <TelemetryModules>
      <Add type="com.microsoft.applicationinsights.web.extensibility.modules.WebRequestTrackingTelemetryModule"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.modules.WebSessionTrackingTelemetryModule"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.modules.WebUserTrackingTelemetryModule"/>
   </TelemetryModules>

   <!-- Events correlation (not required for bare API) -->
   <!-- These initializers add context data to each event -->
   <TelemetryInitializers>
      <Add type="com.microsoft.applicationinsights.web.extensibility.initializers.WebOperationIdTelemetryInitializer"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.initializers.WebOperationNameTelemetryInitializer"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.initializers.WebSessionTelemetryInitializer"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.initializers.WebUserTelemetryInitializer"/>
      <Add type="com.microsoft.applicationinsights.web.extensibility.initializers.WebUserAgentTelemetryInitializer"/>
   </TelemetryInitializers>

</ApplicationInsights>
```

#### Create a common-to-Azure facade to talk to App Insights

All code that needs to interact with Application Insights should import
a single facade to ensure our code uses App Insight consistently, and to 
keep everyone from having to learn all of the details about Application Insights
and getting it configured.

Here's what that might look like:  

```java
    public class AppInsightsFacade {

        @Autowired
        TelemetryClient telemetryClient;

        void captureMessage(/*...*/);
        void captureException(/*...*/);
        void captureEvent(/*...*/);
        void captureRequestHandling(/*...*/);
        void captureDependencyCall(/*...*/);
        
        /* ops to support manual telemetry correlation */
        String getDistributedOperationId() {
            return telemetryClient.getContext().getOperation().getId();
        }
        void setDistributedOperationParentId(String parentOpId) {
            telemetryClient.getContext().getOperation().setParentId(parentOpId);
        }       
         
    }
```

#### Create an Application Insights SDK for Java DpsLogger

`org.opengroup.osdu.core.logging.DpsLogger` describes a Java interface
that accounts for most of the auditing and logging needs of the system, 
including capturing business-level access to data, error handling, etc.

Here's how two of those methods might look. First, here's an example implementation
that would emit an Application Insights 

```java
 public class AppInsightsDpsLog implements org.opengroup.osdu.core.logging.Log {

    @Autowired
    AppInsightsFacade facade;

    private HeadersToLog headerFilter = new HeadersToLog(Collections.emptyList());

    @Override
    public void error(String logname, String message, Exception ex, Map<String, String> labels){
        telemetryClient.trackEvent(String.format("Exception: %s\n%s", message, exString));
        Map<String, String> props = /* copy labels */
        props.put("logname", logname);
        telemetryClient.captureException(ex, props);
    }

    @Override
    public void audit(String logname, AuditPayload payload, Map<String, String> headers){
        Map<String, String> props = headerFilter.createStandardLabelsFromMap(headers);
        props.add(/* copy payload props (from payload.payload) */);
        props.put("logname", logname);
        String msg = /* resolve payload.message */;
        telemetryClient.captureEvent(msg, props, null);
    }

    @Override
    public void request(String logname, Request request, Map<String, String> labels){
        logger.writeRequestEntry(logname,"#RequestLog", request, headerFilter.createStandardLabelsFromMap(labels));
    }

    @Override
    public void info(String logname, String message, Map<String, String> labels){
        logger.writeEntry(logname, Level.INFO, message, headerFilter.createStandardLabelsFromMap(labels));
        telemetryClient.captureTrace("Sending a custom trace....");
    }
        
 }
``` 

#### Use the new common library from within the azure provider, where needed

Per [instructions about distributed transactions](https://docs.microsoft.com/en-us/azure/azure-monitor/app/correlation#telemetry-correlation-in-the-java-sdk),
the Application Insights SDK for Java doesn't automatically correlate distributed 
operations that span into Service Bus.

> Currently, automatic context propagation across messaging technologies (like Kafka, RabbitMQ, and Azure Service Bus) isn't supported. It is possible to code such scenarios manually by using the trackDependency and trackRequest methods. In these methods, a dependency telemetry represents a message being enqueued by a producer. The request represents a message being processed by a consumer. In this case, both operation_id and operation_parentId should be propagated in the message's properties.
 
Thus, we'll need to add code to leverage `trackDependency` when pushing messages onto a bus, and we'll
need to add some code to leverage `trackRequest` (_note: not `trackHttpRequest`_):

Here's what adding `trackDependency` to the outbound message published might look like. 
Note that we're adding a property to the message so that the handling code (a consumer) 
will be able to use the value to ensure the handler work is related back to the original operation.

Note, this pattern would need to be employed wherever messages are
sent on Service Bus.

```java
    public class MessageBusImpl implements IMessageBus {

        @Autowired
        AppInsightsFacade facade;

        /* ... */           
        public void publishMessage(DpsHeaders headers, PubSubInfo... messages) {
            /* ... while building the msg properties, inject the `operation_id`, per 
                   https://docs.microsoft.com/en-us/azure/azure-monitor/app/correlation#telemetry-correlation-in-the-java-sdk*/    
            properties.put("operation_parentId", facade.getDistributedOperationId());
            /* ... then before sending the message, we'd use
                   the facade to signal the dependency */ 
        
            facade.captureDependency(/*...*/);            
        }
    }
```

Here's what adding `trackRequest` to a message consumer might look like. Note, we're using
the `operation_parentId` property from the message to re-establish this operation's context
with its parent.

```java
    public class SBMessageBuilder {
        public RecordChangedMessages getServiceBusMessage(String serviceBusRequest) throws IOException {
            /* ... after the message object is read from JSON, etc. */
            String propParentId = message.getPropety("operation_parentId");
            facade.setDistributedOperationParentId(propParentId);
            facade.captureRequest(/* ... */);            
        }
    }
```

## Follow-on Tasks/Stories

Some follow-on work, coming from this story, might include:
 * Publish example code to artificially trigger an alert, given environment 
 flags / settings, to test dashboards, notifications, etc
 * Begin a service-by-service 'low hanging fruit' remediation 
 (instrument the code for known use cases, build dashboards that reveal the telemetry)
 * Begin a service-by-service comprehensive deep dive (with OSDU team at-large) 
 to uncover more use cases for alerting, etc.
 * Audit/evaluate the impact of Azure Service Limits and how they interact with the system, 
 as deployed. Goal: create alerts that would help operators prevent outages.
 * Ensure App Insights keys are working, place config where needed 
(Spring Boot, pure Java, Logback?, etc). Decide is we should add App Insights code 
into non-Java code at this time.
 * We need to centralize the decisions and advice about using 
 Azure Monitoring somewhere, including:
     * Instructions for building up dashboards, 
     * Various needed settings that aren't covered by automation, 
     * how to add notification information (i.e. add a new user that would be paged if an alert occurs)
     * Describe general coding patterns for sending telemetry to Azure
     * Describe general coding patterns for testing monitoring / alerting

An epic to cover implementing Azure Monitoring  might include these ideas:
 * Set-up Azure Monitoring, App Insights and App Mapping
 * Verify Centralized Logging is working, with example queries
 * Verify that App Service App Insights Site Extensions are enabled 
 (also for Azure Cloud Services and Azure Functions) See the 
 [Quick start guide for Application Insights for Azure cloud services](https://docs.microsoft.com/en-us/azure/azure-monitor/app/cloudservices).
 * Decide on, and implement Azure VM Monitoring (of the Elastic Search deployment)
 * Note that a few "Azure Preview" monitoring capabilities are omitted from 
 scope (for Storage and Database/CosmosDB) but they may need to be considered 
 in the future, as those offerings become GA.

_Also note that we did not consider Azure Sentinal, as part of this story, 
but it also probably deserves consideration amid a security review of the 
overall implementation._

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