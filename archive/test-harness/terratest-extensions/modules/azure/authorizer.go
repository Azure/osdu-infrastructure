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
	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/adal"
	az "github.com/Azure/go-autorest/autorest/azure"
	"os"
	"strings"
)

// DeploymentServicePrincipalAuthorizer - Returns an authorizer configured with the service principal
// used to execute the terraform commands
func DeploymentServicePrincipalAuthorizer() (autorest.Authorizer, error) {
	return ServicePrincipalAuthorizer(
		os.Getenv("ARM_CLIENT_ID"),
		os.Getenv("ARM_CLIENT_SECRET"),
		az.PublicCloud.ResourceManagerEndpoint)
}

// KeyvaultServicePrincipalAuthorizer - gets an OAuthTokenAuthorizer for use with Key Vault
// keys and secrets. Note that Key Vault *Vaults* are managed by Azure Resource
// Manager.
func KeyvaultServicePrincipalAuthorizer() (autorest.Authorizer, error) {
	return ServicePrincipalAuthorizer(
		os.Getenv("ARM_CLIENT_ID"),
		os.Getenv("ARM_CLIENT_SECRET"),
		strings.TrimSuffix(az.PublicCloud.KeyVaultEndpoint, "/"))
}

// ServicePrincipalAuthorizer - Configures a service principal authorizer that can be used to create bearer tokens
func ServicePrincipalAuthorizer(clientID string, clientSecret string, resource string) (autorest.Authorizer, error) {
	oauthConfig, err := adal.NewOAuthConfig(az.PublicCloud.ActiveDirectoryEndpoint, os.Getenv("ARM_TENANT_ID"))
	if err != nil {
		return nil, err
	}

	token, err := adal.NewServicePrincipalToken(*oauthConfig, clientID, clientSecret, resource)
	if err != nil {
		return nil, err
	}

	return autorest.NewBearerAuthorizer(token), nil
}
