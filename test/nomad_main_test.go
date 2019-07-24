package test

import (
	"fmt"
	"math/rand"
	// "os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/packer"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

const (
	IMAGE_EXAMPLE_PATH  = "../examples/nomad-consul-image/nomad-consul.json"
	WORK_DIR            = "./"
	DEFAULT_NUM_CLIENTS = 2
	DEFAULT_NUM_SERVERS = 3

	// Terratest saved value names
	SAVED_GCP_PROJECT_ID  = "GcpProjectId"
	SAVED_GCP_REGION_NAME = "GcpRegionName"
	SAVED_GCP_ZONE_NAME   = "GcpZoneName"

	// Terraform module vars
	TFVAR_NAME_GCP_PROJECT_ID = "gcp_project"
	TFVAR_NAME_GCP_REGION     = "gcp_region"
	TFVAR_NAME_GCP_ZONE       = "gcp_zone"

	TFVAR_NAME_NOMAD_CONSUL_SERVER_CLUSTER_NAME = "nomad_consul_server_cluster_name"
	TFVAR_NAME_NOMAD_CONSUL_SERVER_SOURCE_IMAGE = "nomad_consul_server_source_image"

	TFVAR_NAME_NOMAD_CLIENT_CLUSTER_NAME = "nomad_client_cluster_name"
	TFVAR_NAME_NOMAD_CLIENT_SOURCE_IMAGE = "nomad_client_source_image"

	TFVAR_NAME_NOMAD_SERVER_CLUSTER_NAME = "nomad_server_cluster_name"
	TFVAR_NAME_NOMAD_SERVER_SOURCE_IMAGE = "nomad_server_source_image"

	TFVAR_NAME_CONSUL_SERVER_CLUSTER_NAME = "consul_server_cluster_name"
	TFVAR_NAME_CONSUL_SERVER_SOURCE_IMAGE = "consul_server_source_image"

	TFVAR_NAME_NOMAD_CONSUL_SERVER_CLUSTER_SIZE = "nomad_consul_server_cluster_size"
	TFVAR_NAME_NOMAD_SERVER_CLUSTER_SIZE        = "nomad_server_cluster_size"
	TFVAR_NAME_NOMAD_CLIENT_CLUSTER_SIZE        = "nomad_client_cluster_size"

	TFOUT_COLOCATED_SERVER_INSTANCE_GROUP_NAME = "nomad_server_instance_group_name"
	TFOUT_SEPARATE_SERVER_INSTANCE_GROUP_NAME  = "nomad_server_instance_group_name"
)

type testCase struct {
	Name string                   // Name of the test
	Func func(*testing.T, string) // Function that runs the test
}

var testCases = []testCase{
	{
		"TestNomadColocatedCluster",
		runNomadColocatedCluster,
	},
	{
		"TestDeployNomadConsulSeparateCluster",
		runNomadConsulSeparateCluster,
	},
}

var packerBuildNames = []string{
	"ubuntu16-image",
	"ubuntu18-image",
}

func TestMainNomadCluster(t *testing.T) {
	// For convenience - uncomment these as well as the "os" import
	// when doing local testing if you need to skip any sections.
	// os.Setenv("SKIP_build_images", "true")
	// os.Setenv("SKIP_delete_images", "true")
	// os.Setenv("SKIP_", "true")
	t.Parallel()

	test_structure.RunTestStage(t, "build_images", func() {
		projectID := gcp.GetGoogleProjectIDFromEnvVar(t)
		// Limiting tests to us-east1 due to quota of IP addresses in use
		region := gcp.GetRandomRegion(t, projectID, []string{"us-east1"}, nil)
		zone := gcp.GetRandomZoneForRegion(t, projectID, region)

		imagePackerOptions := map[string]*packer.Options{}
		for _, packerBuildName := range packerBuildNames {
			imagePackerOptions[packerBuildName] = &packer.Options{
				Template: IMAGE_EXAMPLE_PATH,
				Only:     packerBuildName,
				Vars: map[string]string{
					"project_id": projectID,
					"zone":       zone,
				},
			}
		}

		imageIds := packer.BuildArtifacts(t, imagePackerOptions)
		for packerBuildName, imageId := range imageIds {
			test_structure.SaveString(t, WORK_DIR, fmt.Sprintf("%s-id", packerBuildName), imageId)
		}

		test_structure.SaveString(t, WORK_DIR, SAVED_GCP_PROJECT_ID, projectID)
		test_structure.SaveString(t, WORK_DIR, SAVED_GCP_REGION_NAME, region)
		test_structure.SaveString(t, WORK_DIR, SAVED_GCP_ZONE_NAME, zone)
	})

	defer test_structure.RunTestStage(t, "delete_images", func() {
		projectID := test_structure.LoadString(t, WORK_DIR, SAVED_GCP_PROJECT_ID)
		for _, packerBuildName := range packerBuildNames {
			imageName := test_structure.LoadString(t, WORK_DIR, fmt.Sprintf("%s-id", packerBuildName))
			image := gcp.FetchImage(t, projectID, imageName)
			defer image.DeleteImage(t)
		}
	})

	t.Run("group", func(t *testing.T) {
		runAllTests(t)
	})
}

func runAllTests(t *testing.T) {
	rand.Seed(time.Now().UnixNano())
	for _, testCase := range testCases {
		// This re-assignment necessary, because the variable testCase is defined and set outside the forloop.
		// As such, it gets overwritten on each iteration of the forloop. This is fine if you don't have concurrent code in the loop,
		// but in this case, because you have a t.Parallel, the t.Run completes before the test function exits,
		// which means that the value of testCase might change.
		// More information at:
		// "Be Careful with Table Driven Tests and t.Parallel()"
		// https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
		testCase := testCase
		t.Run(fmt.Sprintf("%sWithUbuntu16", testCase.Name), func(t *testing.T) {
			t.Parallel()
			testCase.Func(t, "ubuntu16-image")
		})
		t.Run(fmt.Sprintf("%sWithUbuntu18", testCase.Name), func(t *testing.T) {
			t.Parallel()
			testCase.Func(t, "ubuntu18-image")
		})
	}
}
