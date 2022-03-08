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

package azure

import (
	"context"
	keyvaultSecret "github.com/Azure/azure-sdk-for-go/services/keyvault/2016-10-01/keyvault"
	"github.com/Azure/azure-sdk-for-go/services/keyvault/mgmt/2018-02-14/keyvault"
	"testing"
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
