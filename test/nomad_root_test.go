package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func runNomadColocatedCluster(t *testing.T, packerBuildName string) {
	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", ".")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		projectID := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_PROJECT_ID)
		region := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_REGION_NAME)
		zone := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_ZONE_NAME)
		imageID := test_structure.LoadString(t, WORK_DIR, fmt.Sprintf("%s-id", packerBuildName))

		// GCP only supports lowercase names for some resources
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				TFVAR_NAME_GCP_PROJECT_ID:                   projectID,
				TFVAR_NAME_GCP_REGION:                       region,
				TFVAR_NAME_GCP_ZONE:                         zone,
				TFVAR_NAME_NOMAD_CONSUL_SERVER_CLUSTER_NAME: fmt.Sprintf("consul-nomad-server-%s", uniqueID),
				TFVAR_NAME_NOMAD_CONSUL_SERVER_SOURCE_IMAGE: imageID,
				TFVAR_NAME_NOMAD_CLIENT_CLUSTER_NAME:        fmt.Sprintf("nomad-client-%s", uniqueID),
				TFVAR_NAME_NOMAD_CLIENT_SOURCE_IMAGE:        imageID,
				TFVAR_NAME_NOMAD_CONSUL_SERVER_CLUSTER_SIZE: DEFAULT_NUM_SERVERS,
				TFVAR_NAME_NOMAD_CLIENT_CLUSTER_SIZE:        DEFAULT_NUM_CLIENTS,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		instanceGroupName := terraform.OutputRequired(t, terraformOptions, TFOUT_COLOCATED_SERVER_INSTANCE_GROUP_NAME)

		ip := getClusterNodeIP(t, instanceGroupName)
		testNomadCluster(t, ip)
	})
}
