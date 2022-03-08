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
	"encoding/json"
	"fmt"
	"github.com/Azure/azure-sdk-for-go/services/web/mgmt/2018-02-01/web"
	"testing"
)

func webAppClient(subscriptionID string) (*web.AppsClient, error) {
	authorizer, err := DeploymentServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	client := web.NewAppsClient(subscriptionID)
	client.Authorizer = authorizer
	return &client, nil
}

// WebAppCDUriE - Return the CD URL that can be used to trigger an ACR pull and redeploy
func WebAppCDUriE(subscriptionID string, resourceGroupName string, webAppName string) (string, error) {

	client, err := webAppClient(subscriptionID)
	if err != nil {
		return "", err
	}

	ctx := context.Background()
	httpResponse, err := client.ListPublishingCredentials(ctx, resourceGroupName, webAppName)
	if err != nil {
		return "", err
	}

	err = httpResponse.WaitForCompletion(ctx, client.Client)
	if err != nil {
		return "", err
	}

	var jsonResponse map[string]interface{}
	err = json.NewDecoder(httpResponse.Response().Body).Decode(&jsonResponse)
	if err != nil {
		return "", err
	}

	properties, propertiesExist := jsonResponse["properties"]
	if !propertiesExist {
		return "", fmt.Errorf("`properties` attribute missing from response of ListPublishingCredentials()")
	}

	propertiesMap := properties.(map[string]interface{})
	scmURI, scmURIExists := propertiesMap["scmUri"]
	if !scmURIExists {
		return "", fmt.Errorf("`properties.scmUri` attribute missing from response of ListPublishingCredentials()")
	}

	return scmURI.(string) + "/docker/hook", nil
}

// WebAppCDUri - Like WebAppCDUriE but fails in the case an error is returned
func WebAppCDUri(t *testing.T, subscriptionID string, resourceGroupName string, webAppName string) string {
	cdURI, err := WebAppCDUriE(subscriptionID, resourceGroupName, webAppName)
	if err != nil {
		t.Fatal(err)
	}
	return cdURI
}

// WebAppSiteConfigurationE - Return the configuration for a webapp
func WebAppSiteConfigurationE(subscriptionID string, resourceGroupName string, webAppName string) (*web.SiteConfig, error) {

	client, err := webAppClient(subscriptionID)
	if err != nil {
		return nil, err
	}

	appConfiguration, err := client.GetConfiguration(context.Background(), resourceGroupName, webAppName)
	if err != nil {
		return nil, err
	}

	return appConfiguration.SiteConfig, nil
}

// WebAppAuthSettingsClientIDE - Return the authn/authz settings for a webapp
func WebAppAuthSettingsClientIDE(subscriptionID string, resourceGroupName string, webAppName string) (*string, error) {

	client, err := webAppClient(subscriptionID)
	if err != nil {
		return nil, err
	}

	authConfiguration, err := client.GetAuthSettings(context.Background(), resourceGroupName, webAppName)
	if err != nil {
		return nil, err
	}

	return authConfiguration.SiteAuthSettingsProperties.ClientID, nil
}

// WebAppSiteConfiguration - Like WebAppSiteConfigurationE but fails in the case an error is returned
func WebAppSiteConfiguration(t *testing.T, subscriptionID string, resourceGroupName string, webAppName string) *web.SiteConfig {
	appConfiguration, err := WebAppSiteConfigurationE(subscriptionID, resourceGroupName, webAppName)
	if err != nil {
		t.Fatal(err)
	}
	return appConfiguration
}

// WebAppEasyAuthClientID - Like WebAppAuthSettingsClientIDE but fails in the case an error is returned
func WebAppEasyAuthClientID(t *testing.T, subscriptionID string, resourceGroupName string, webAppName string) *string {
	clientID, err := WebAppAuthSettingsClientIDE(subscriptionID, resourceGroupName, webAppName)
	if err != nil {
		t.Fatal(err)
	}
	return clientID
}
