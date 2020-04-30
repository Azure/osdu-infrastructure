package azure

import (
	"os"
	"strings"

	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/adal"
	az "github.com/Azure/go-autorest/autorest/azure"
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
