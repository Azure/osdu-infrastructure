package azure

import (
	"context"
	"testing"

	keyvaultSecret "github.com/Azure/azure-sdk-for-go/services/keyvault/2016-10-01/keyvault"
	"github.com/Azure/azure-sdk-for-go/services/keyvault/mgmt/2018-02-14/keyvault"
)

func keyVaultClientE(subscriptionID string) (*keyvault.VaultsClient, error) {
	authorizer, err := DeploymentServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	client := keyvault.NewVaultsClient(subscriptionID)
	client.Authorizer = authorizer
	return &client, err
}

func keyVaultSecretClientE() (*keyvaultSecret.BaseClient, error) {
	authorizer, err := KeyvaultServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	client := keyvaultSecret.New()
	client.Authorizer = authorizer
	return &client, err
}

// KeyVaultNetworkAclsE - Return the newtwork ACLs for a KeyVault instance
func KeyVaultNetworkAclsE(subscriptionID string, resourceGroupName string, keyVaultName string) (*keyvault.NetworkRuleSet, error) {

	client, err := keyVaultClientE(subscriptionID)
	if err != nil {
		return nil, err
	}

	vault, err := client.Get(context.Background(), resourceGroupName, keyVaultName)
	if err != nil {
		return nil, err
	}

	return vault.Properties.NetworkAcls, nil
}

// KeyVaultNetworkAcls - Like KeyVaultNetworkAclsE but fails in the case an error is returned
func KeyVaultNetworkAcls(t *testing.T, subscriptionID string, resourceGroupName string, keyVaultName string) *keyvault.NetworkRuleSet {
	acls, err := KeyVaultNetworkAclsE(subscriptionID, resourceGroupName, keyVaultName)
	if err != nil {
		t.Fatal(err)
	}
	return acls
}

// GetKeyVaultSecretValue - Returns the keyvault secret value
func GetKeyVaultSecretValue(t *testing.T, vaultURI string, secretName string, secretVersion string) *string {
	client, err := keyVaultSecretClientE()
	if err != nil {
		t.Fatal(err)
	}
	secret, err := client.GetSecret(context.Background(), vaultURI, secretName, secretVersion)

	if err != nil {
		t.Fatal(err)
	}

	return secret.Value
}
