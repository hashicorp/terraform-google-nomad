package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func runNomadCluster(t *testing.T) {
	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", ".")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		projectID := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_PROJECT_ID)
		region := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_REGION_NAME)
		zone := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_ZONE_NAME)
		imageID := test_structure.LoadArtifactID(t, WORK_DIR)

		// GCP only supports lowercase names for some resources
		uniqueID := strings.ToLower(random.UniqueId())

		terraformOptions := &terraform.Options{
			TerraformDir: exampleDir,
			Vars: map[string]interface{}{
				TFVAR_NAME_GCP_PROJECT_ID:      projectID,
				TFVAR_NAME_GCP_REGION:          region,
				TFVAR_NAME_GCP_ZONE:            zone,
				TFVAR_NAME_CONSUL_CLUSTER_NAME: fmt.Sprintf("consul-test-%s", uniqueID),
				TFVAR_NAME_CONSUL_SOURCE_IMAGE: imageID,
				TFVAR_NAME_NOMAD_CLUSTER_NAME:  fmt.Sprintf("nomad-test-%s", uniqueID),
				TFVAR_NAME_NOMAD_SOURCE_IMAGE:  imageID,
			},
		}

		test_structure.SaveTerraformOptions(t, exampleDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		logger.Logf(t, "TODO: validate nomad cluster")
	})
}
