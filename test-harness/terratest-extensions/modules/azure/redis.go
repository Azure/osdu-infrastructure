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
	"crypto/tls"
	"fmt"
	"github.com/Azure/azure-sdk-for-go/services/redis/mgmt/2018-03-01/redis"
	redis7Api "github.com/go-redis/redis/v7"
	"testing"
	"time"
)

func redisAzureClientE(subscriptionID string) (*redis.Client, error) {
	authorizer, err := DeploymentServicePrincipalAuthorizer()
	if err != nil {
		return nil, err
	}

	client := redis.NewClient(subscriptionID)
	client.Authorizer = authorizer
	return &client, err
}

func redisClientE(hostname string, accessKey string) (*redis7Api.Client, error) {
	client := redis7Api.NewClient(&redis7Api.Options{
		Addr:        hostname,
		Password:    accessKey,
		DB:          0,
		TLSConfig:   &tls.Config{},
		DialTimeout: 10000000000,
	})

	healthCheck := client.Ping()
	pingStatus, err := healthCheck.Result()

	if err != nil {
		return nil, err
	}

	//  A redis cluster that returns a PONG is fully functional and works as expected
	if pingStatus != "PONG" {
		err = fmt.Errorf("REDIS ping status failed with result - %s", pingStatus)
	}

	return client, err
}

// RedisClient - Instantiate a new client from redis's collection pool
func RedisClient(t *testing.T, hostname string, accessKey string) *redis7Api.Client {
	client, err := redisClientE(hostname, accessKey)

	if err != nil {
		t.Fatal(fmt.Errorf("Failed to create Redis API client: %v", err))
	}

	return client
}

// SetRedisCacheEntry - Sets a cache entry on the target redis cluster
func SetRedisCacheEntry(t *testing.T, client *redis7Api.Client, cacheKey string, cacheValue interface{}, expiration time.Duration) string {
	setCmdResponse := client.Set(cacheKey, cacheValue, expiration)
	result, err := setCmdResponse.Result()

	if err != nil {
		t.Fatal(err)
	}

	return result
}

// GetRedisCacheEntryValueStr - Retrieves a cache entry from the target redis cluster
func GetRedisCacheEntryValueStr(t *testing.T, client *redis7Api.Client, cacheKey string) string {
	getCmdResponse := client.Get(cacheKey)
	result, err := getCmdResponse.Result()
	if err != nil {
		t.Fatal(err)
	}

	return result
}

// RemoveRedisCacheEntry - Removes a cache entry from the target redis cluster
func RemoveRedisCacheEntry(t *testing.T, client *redis7Api.Client, cacheKey string) int64 {
	deleteCmdResponse := client.Del(cacheKey)
	result, err := deleteCmdResponse.Result()

	if err != nil {
		t.Fatal(err)
	}

	return result
}

// ListCachesByResourceGroup - Lists the caches by resource group
func ListCachesByResourceGroup(t *testing.T, subscriptionID string, resourceGroupName string) *[]redis.ResourceType {
	caches, err := listCachesByResourceGroupE(subscriptionID, resourceGroupName)

	if err != nil {
		t.Fatal(err)
	}

	return caches
}

func listCachesByResourceGroupE(subscriptionID string, resourceGroupName string) (*[]redis.ResourceType, error) {
	client, err := redisAzureClientE(subscriptionID)

	if err != nil {
		return nil, err
	}

	ctx := context.Background()
	results := []redis.ResourceType{}

	paginatedResponse, err := client.ListByResourceGroup(ctx, resourceGroupName)

	if err != nil {
		return nil, err
	}

	for paginatedResponse.NotDone() {
		results = append(results, paginatedResponse.Values()...)
		err = paginatedResponse.Next()
		if err != nil {
			return nil, err
		}
	}

	return &results, nil
}

// GetCacheE - Retrieves the properties of a cache.
func GetCacheE(subscriptionID string, resourceGroupName string, cacheName string) (*redis.ResourceType, error) {
	client, err := redisAzureClientE(subscriptionID)

	if err != nil {
		return nil, err
	}

	ctx := context.Background()

	resourceType, err := client.Get(ctx, resourceGroupName, cacheName)

	if err != nil {
		return nil, err
	}

	return &resourceType, nil
}

// GetCache - Retrieves the properties of a cache.
func GetCache(t *testing.T, subscriptionID string, resourceGroupName string, cacheName string) *redis.ResourceType {
	resourceType, err := GetCacheE(subscriptionID, resourceGroupName, cacheName)

	if err != nil {
		t.Fatal(err)
	}

	return resourceType
}
