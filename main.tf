# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A NOMAD CLUSTER CO-LOCATED WITH A CONSUL CLUSTER IN GOOGLE CLOUD
# These templates show an example of how to use the nomad-cluster module to deploy a Nomad cluster in GCP. This cluster
# has Consul colocated on the same nodes.
#
# We deploy two Managed Instance Groups for Nomad: one with a small number of Nomad server nodes and one with an
# arbitrary number of Nomad client nodes. Note that these templates assume that the Image you provide via the
# nomad_image input variable is built from the examples/nomad-consul-image/nomad-consul.json Packer template.
#
# We also deploy one Managed Instance Group for Consul which has a small number of Consul server nodes. Note that these
# templates assume that the Image you provide via the consul_image input variable is built from the
# examples/consul-image/consul.json Packer template in the Consul GCP Module.
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

terraform {
  # The modules used in this example have been updated with 0.12 syntax, which means the example is no longer
  # compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD SERVER NODES
# Note that we use the consul-cluster module to deploy both the Nomad and Consul nodes on the same servers
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_and_consul_servers" {
  source = "git::git@github.com:hashicorp/terraform-google-consul.git//modules/consul-cluster?ref=v0.5.0"

  gcp_project_id = var.gcp_project
  gcp_region     = var.gcp_region

  cluster_name     = var.nomad_consul_server_cluster_name
  cluster_size     = var.nomad_consul_server_cluster_size
  cluster_tag_name = var.nomad_consul_server_cluster_name
  machine_type     = var.nomad_consul_server_cluster_machine_type

  source_image    = var.nomad_consul_server_source_image
  startup_script  = data.template_file.startup_script_nomad_consul_server.rendered
  shutdown_script = data.template_file.shutdown_script_nomad_consul_server.rendered

  # WARNING!
  # In a production setting, we strongly recommend only launching a Nomad/Consul Server cluster as private nodes.
  # Note that the only way to reach private nodes via SSH is to first SSH into another node that is not private.
  assign_public_ip_addresses = true

  # To enable external access to the Nomad Cluster, enter the approved CIDR Blocks below.
  allowed_inbound_cidr_blocks_http_api = ["0.0.0.0/0"]

  # Enable the Nomad clients to reach the Nomad/Consul Server Cluster
  allowed_inbound_tags_http_api = [var.nomad_client_cluster_name]
  allowed_inbound_tags_dns      = [var.nomad_client_cluster_name]
}

# Enable Firewall Rules to open up Nomad-specific ports
module "nomad_firewall_rules" {
  source = "./modules/nomad-firewall-rules"

  cluster_name     = var.nomad_consul_server_cluster_name
  cluster_tag_name = var.nomad_consul_server_cluster_name

  http_port = 4646
  rpc_port  = 4647
  serf_port = 4648

  allowed_inbound_cidr_blocks_http = ["0.0.0.0/0"]
}

# Render the Startup Script that will run on each Nomad Instance on boot. This script will configure and start Nomad.
data "template_file" "startup_script_nomad_consul_server" {
  template = file(
    "${path.module}/examples/root-example/startup-script-nomad-consul-server.sh",
  )

  vars = {
    num_servers                    = var.nomad_consul_server_cluster_size
    consul_server_cluster_tag_name = var.nomad_consul_server_cluster_name
  }
}
data "template_file" "shutdown_script_nomad_consul_server" {
  template = file(
    "${path.module}/examples/root-example/shutdown-script-nomad-consul-server.sh",
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD CLIENT NODES
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-google-nomad.git//modules/nomad-cluster?ref=v0.0.1"
  source = "./modules/nomad-cluster"

  gcp_region = var.gcp_region

  cluster_name     = var.nomad_client_cluster_name
  cluster_size     = var.nomad_client_cluster_size
  cluster_tag_name = var.nomad_client_cluster_name
  machine_type     = var.nomad_client_machine_type

  source_image   = var.nomad_client_source_image
  startup_script = data.template_file.startup_script_nomad_client.rendered

  # We strongly recommend setting this to "false" in a production setting. Your Nomad cluster has no reason to be
  # publicly accessible! However, for testing and demo purposes, it is more convenient to launch a publicly accessible
  # Nomad cluster.
  assign_public_ip_addresses = true

  # These inbound clients need only receive requests from Nomad Server and Consul
  allowed_inbound_cidr_blocks_http = []
  allowed_inbound_tags_http        = [var.nomad_consul_server_cluster_name]
  allowed_inbound_tags_rpc         = [var.nomad_consul_server_cluster_name]
  allowed_inbound_tags_serf        = [var.nomad_consul_server_cluster_name]
}

# Render the Startup Script that will configure and run both Consul and Nomad in client mode.
data "template_file" "startup_script_nomad_client" {
  template = file(
    "${path.module}/examples/root-example/startup-script-nomad-client.sh",
  )

  vars = {
    consul_server_cluster_tag_name = var.nomad_consul_server_cluster_name
  }
}
