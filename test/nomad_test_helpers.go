package test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

// Fetches the IP of one random node in the API
func getClusterNodeIP(t *testing.T, instanceGroupName string) string {
	projectID := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_PROJECT_ID)
	region := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_REGION_NAME)

	maxRetries := 10
	sleepBetweenRetries := 10 * time.Second

	ip := retry.DoWithRetry(t, fmt.Sprintf("Waiting for instances in group"), maxRetries, sleepBetweenRetries, func() (string, error) {
		// the instance group has to be fetched within the retry because the size of the group might have changed in the meantime
		instanceGroup := gcp.FetchRegionalInstanceGroup(t, projectID, region, instanceGroupName)

		instance, err := instanceGroup.GetRandomInstanceE(t)
		if err != nil {
			return "", err
		}

		ip, err := instance.GetPublicIpE(t)
		if err != nil {
			return "", err
		}

		return ip, nil
	})

	return ip
}

// Use a Nomad client to connect to the given node and use it to verify that:
//
// 1. The Nomad cluster has deployed
// 2. The cluster has the expected number of server nodes
// 2. The cluster has the expected number of client nodes
func testNomadCluster(t *testing.T, nodeIPAddress string) {
	maxRetries := 20
	sleepBetweenRetries := 5 * time.Second

	response := retry.DoWithRetry(t, "Check Nomad cluster has expected number of servers and clients", maxRetries, sleepBetweenRetries, func() (string, error) {
		clients, err := callNomadAPI(t, nodeIPAddress, "v1/nodes")
		if err != nil {
			return "", err
		}

		if len(clients) != DEFAULT_NUM_CLIENTS {
			return "", fmt.Errorf("Expected the cluster to have %d clients, but found %d", DEFAULT_NUM_CLIENTS, len(clients))
		}

		servers, err := callNomadAPI(t, nodeIPAddress, "v1/status/peers")
		if err != nil {
			return "", err
		}

		if len(servers) != DEFAULT_NUM_SERVERS {
			return "", fmt.Errorf("Expected the cluster to have %d servers, but found %d", DEFAULT_NUM_SERVERS, len(servers))
		}

		return fmt.Sprintf("Got back expected number of clients (%d) and servers (%d)", len(clients), len(servers)), nil
	})

	logger.Logf(t, "Nomad cluster is properly deployed: %s", response)
}

// A quick, hacky way to call the Nomad HTTP API: https://www.nomadproject.io/docs/http/index.html
func callNomadAPI(t *testing.T, nodeIPAddress string, path string) ([]interface{}, error) {
	url := fmt.Sprintf("http://%s:4646/%s", nodeIPAddress, path)
	logger.Logf(t, "Making an HTTP GET to URL %s", url)

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	logger.Logf(t, "Response from Nomad for URL %s: %s", url, string(body))

	result := []interface{}{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return result, nil
}
