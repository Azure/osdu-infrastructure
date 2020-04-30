package test

import (
	"fmt"
	"sort"
	"testing"

	"github.com/microsoft/cobalt/test-harness/infratests"
)

func appendKeyVaultTests(t *testing.T, description infratests.ResourceDescription) {
	kvBasicExpectations(t, description)
	kvAccessPolicyExpectations(t, description)
	kvSecretExpectations(t, description)
}

func kvBasicExpectations(t *testing.T, description infratests.ResourceDescription) {
	k1 := "module.keyvault.azurerm_key_vault.keyvault"
	e1 := asMap(t, `{
	   "sku_name":    "standard"
	}`)
	description[k1] = e1
}

func kvSecretExpectations(t *testing.T, description infratests.ResourceDescription) {
	expectedKeys := []string{
		"aad-client-id",
		"appinsights-key",
		"sb-connection",
		"elastic-endpoint",
		"elastic-password",
		"elastic-username",
		"cosmos-endpoint",
		"cosmos-primary-key",
		"cosmos-connection",
		"entitlement-key",
		"storage-account-key",
		"app-dev-sp-username",
		"app-dev-sp-password",
		"app-dev-sp-tenant-id",
	}

	// The unit test fixture will expect these secrets to match ordinals returned by terraform, which sorts by name
	sort.Strings(expectedKeys)
	for index, value := range expectedKeys {
		key := fmt.Sprintf("module.keyvault_secrets.azurerm_key_vault_secret.secret[%v]", index)
		val := asMap(t, fmt.Sprintf(`{"name": "%s"}`, value))
		description[key] = val
	}
}

func kvAccessPolicyExpectations(t *testing.T, description infratests.ResourceDescription) {
	e1 := asMap(t, `{
	   "certificate_permissions": ["update", "delete", "get", "list"],
       "secret_permissions": ["set", "delete", "get", "list"],
       "key_permissions": ["update", "delete", "get", "list"]
	}`)
	k1 := "module.app_management_service_principal_keyvault_access_policy.azurerm_key_vault_access_policy.keyvault[0]"
	description[k1] = e1

	e2 := asMap(t, `{
       "certificate_permissions": ["create", "delete", "get", "list"],
       "secret_permissions": ["set", "delete", "get", "list"],
       "key_permissions": ["create", "delete", "get"]
    }`)
	k2 := "module.keyvault.module.deployment_service_principal_keyvault_access_policies.azurerm_key_vault_access_policy.keyvault[0]"
	description[k2] = e2

	e3 := asMap(t, `{
       "certificate_permissions": ["get", "list"],
       "secret_permissions": ["get", "list"],
       "key_permissions": ["get", "list"]
    }`)
	k3 := "module.authn_app_service_keyvault_access_policy.azurerm_key_vault_access_policy.keyvault[0]"
	description[k3] = e3
}
