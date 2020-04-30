package azure

import (
	"context"
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/storage/mgmt/2019-04-01/storage"
)

func storageClientE(subscriptionID string) (*storage.BlobContainersClient, error) {
	authorizer, err := DeploymentServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	client := storage.NewBlobContainersClient(subscriptionID)
	client.Authorizer = authorizer
	return &client, err
}

func listAccountContainers(client *storage.BlobContainersClient, resourceGroupName string, accountName string) (*[]storage.ListContainerItem, error) {
	MaxContainerPageSize := "10"
	paginatedResponse, err := client.List(context.Background(), resourceGroupName, accountName, "", MaxContainerPageSize, "")

	if err != nil {
		return nil, err
	}

	return paginatedResponse.Value, nil

	// results := []storage.ListContainerItem{}

	// for paginatedResponse.NotDone() {
	// 	results = append(results, paginatedResponse.Values()...)
	// 	err = paginatedResponse.Next()
	// 	if err != nil {
	// 		return nil, err
	// 	}
	// }

	// return &results, nil
}

// ListAccountContainers - Lists the containers for a target storage account
func ListAccountContainers(t *testing.T, subscriptionID string, resourceGroupName string, accountName string) *[]storage.ListContainerItem {
	client, err := storageClientE(subscriptionID)
	if err != nil {
		t.Fatal(err)
	}

	containers, err := listAccountContainers(client, resourceGroupName, accountName)

	if err != nil {
		t.Fatal(err)
	}

	return containers
}
