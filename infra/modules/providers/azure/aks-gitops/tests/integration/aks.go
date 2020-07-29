//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

package integration

import (
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/microsoft/cobalt/test-harness/infratests"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func validateKeyvaultFlexVolNamespace(t *testing.T, kubeConfigFile string) {
	keyvaultNamespace := "kv"
	options := *k8s.NewKubectlOptions("", kubeConfigFile)
	options.Namespace = keyvaultNamespace
	expectedPodCount := 3
	k8s.WaitUntilNumPodsCreated(t, &options, metav1.ListOptions{}, expectedPodCount, 30, 10*time.Second)
}

func validateKeyvaultServicePrincipalSecret(t *testing.T, kubeConfigFile string, clientIDOutputName string, output infratests.TerraformOutput) {
	secretNamespace := "default"
	options := *k8s.NewKubectlOptions("", kubeConfigFile)
	spClientIDExpected := output[clientIDOutputName].(string)
	options.Namespace = secretNamespace

	secret := *k8s.GetSecret(t, &options, "kvcreds")
	spClientIDActual := string(secret.Data["clientid"])

	require.Equal(t, spClientIDExpected, spClientIDActual, "Expect Kubernetes kvcreds secret client id to match output")
}

func validateDeployedWebApp(t *testing.T, kubeConfigFile string, k8ServiceName string, expectedBodySubstring string) {
	webAppNamespace := "default"
	options := *k8s.NewKubectlOptions("", kubeConfigFile)
	options.Namespace = webAppNamespace
	k8s.WaitUntilServiceAvailable(t, &options, k8ServiceName, 30, 10*time.Second)

	service := k8s.GetService(t, &options, k8ServiceName)
	loadBalancerIP := service.Status.LoadBalancer.Ingress[0].IP
	hostname := fmt.Sprintf("http://%s:%d", loadBalancerIP, service.Spec.Ports[0].Port)
	maxRetries := 60
	timeBetweenRetries := 5 * time.Second

	_reqErr := http_helper.HttpGetWithRetryWithCustomValidationE(t, hostname, maxRetries, timeBetweenRetries, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, expectedBodySubstring)
	})

	if _reqErr != nil {
		errorMsg := fmt.Sprintf("Error connecting to external load balancer: %s", hostname)
		t.Fatal(errorMsg)
	}
}

// ValidateFluxNamespace - Validates the resources running within the Flux namespace are fully operational
func validateFluxNamespace(t *testing.T, kubeConfigFile string) {
	fluxNamespace := "flux"
	fluxAppLabel := "flux"
	options := *k8s.NewKubectlOptions("", kubeConfigFile)
	options.Namespace = fluxNamespace
	expectedPodCount := 2
	filters := metav1.ListOptions{
		LabelSelector: fmt.Sprintf("app=%s", fluxAppLabel),
	}

	k8s.WaitUntilNumPodsCreated(t, &options, metav1.ListOptions{}, expectedPodCount, 30, 10*time.Second)

	pods := k8s.ListPods(t, &options, filters)
	for _, pod := range pods {
		k8s.WaitUntilPodAvailable(t, &options, pod.Name, 30, 10*time.Second)
	}
}

// BaselineClusterAssertions - Runs the suite of baseline tests to validate the cluster is fully functional
func BaselineClusterAssertions(kubeConfigFile string, namespaceOutputAttribute string) func(t *testing.T, output infratests.TerraformOutput) {
	return func(t *testing.T, output infratests.TerraformOutput) {
		t.Parallel()

		validateFluxNamespace(t, kubeConfigFile)
		validateAADIdentityControllers(t, kubeConfigFile, output[namespaceOutputAttribute].(string))
		validateAADIdentityCustomResources(t, kubeConfigFile, output[namespaceOutputAttribute].(string))

	}
}

func validatePodsAreAvailable(t *testing.T, kubeConfigFile string, podLabelKey string, podLabelValue string, expectedPodCount int, namespace string) {
	options := *k8s.NewKubectlOptions("", kubeConfigFile)
	options.Namespace = namespace
	filters := metav1.ListOptions{
		LabelSelector: fmt.Sprintf("%s=%s", podLabelKey, podLabelValue),
	}

	k8s.WaitUntilNumPodsCreated(t, &options, filters, expectedPodCount, 30, 10*time.Second)

	pods := k8s.ListPods(t, &options, filters)

	for _, pod := range pods {
		k8s.WaitUntilPodAvailable(t, &options, pod.Name, 30, 10*time.Second)
	}
}

func validateCustomResource(t *testing.T, kubeConfigFile string, namespace string, crname string, expected string) {
	options := k8s.NewKubectlOptions("", kubeConfigFile)
	output, err := k8s.RunKubectlAndGetOutputE(t, options, "get", crname, "--namespace="+namespace)
	if err != nil || !strings.Contains(output, expected) {
		t.Fatal(err)
	} else {
		fmt.Println("Custom resource verification complete" + crname + "-" + expected)
	}
}

// ValidateAADIdentityControllers - Validates the AAD pod controller agents are available
func validateAADIdentityControllers(t *testing.T, kubeConfigFile string, namespace string) {
	validatePodsAreAvailable(t, kubeConfigFile, "app.kubernetes.io/component", "mic", 2, namespace)
	validatePodsAreAvailable(t, kubeConfigFile, "app.kubernetes.io/component", "nmi", 3, namespace)
}

func validateAADIdentityCustomResources(t *testing.T, kubeConfigFile string, namespace string) {
	// validateCustomResource(t, kubeConfigFile, namespace, "AzureIdentity", "sdmspodidentity")
	// validateCustomResource(t, kubeConfigFile, namespace, "AzureIdentityBinding", "sdmspodidentitybinding")
}
