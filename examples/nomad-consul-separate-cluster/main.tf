# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A NOMAD CLUSTER AND A SEPARATE CONSUL CLUSTER IN GOOGLE CLOUD
# These templates show an example of how to use the nomad-cluster module to deploy a Nomad cluster in GCP. This cluster
# connects to Consul running in a separate cluster.
#
# We deploy two Managed Instance Groups for Nomad: one with a small number of Nomad server nodes and one with n
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
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-google-nomad.git//modules/nomad-cluster?ref=v0.0.1"
  source = "../../modules/nomad-cluster"

  gcp_region = var.gcp_region

  cluster_name     = var.nomad_server_cluster_name
  cluster_size     = var.nomad_server_cluster_size
  cluster_tag_name = var.nomad_server_cluster_name
  machine_type     = var.nomad_server_cluster_machine_type

  source_image   = var.nomad_server_source_image
  startup_script = data.template_file.startup_script_nomad_server.rendered

  # WARNING!
  # In a production setting, we strongly recommend only launching a Nomad Server cluster as private nodes.
  # Note that the only way to reach private nodes via SSH is to first SSH into another node that is not private.
  assign_public_ip_addresses = true

  # To enable external access to the Nomad Cluster, enter the approved CIDR Blocks below.
  allowed_inbound_cidr_blocks_http = ["0.0.0.0/0"]

  # Enable the Consul Cluster to reach the Nomad Cluster
  allowed_inbound_tags_http = [var.consul_server_cluster_name, var.nomad_client_cluster_name]
  allowed_inbound_tags_rpc  = [var.consul_server_cluster_name, var.nomad_client_cluster_name]
  allowed_inbound_tags_serf = [var.consul_server_cluster_name, var.nomad_client_cluster_name]
}

# Render the Startup Script that will run on each Nomad Instance on boot. This script will configure and start Nomad.
data "template_file" "startup_script_nomad_server" {
  template = file("${path.module}/startup-script-nomad-server.sh")

  vars = {
    num_servers                    = var.nomad_server_cluster_size
    consul_server_cluster_tag_name = var.consul_server_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_cluster" {
  source = "git::git@github.com:hashicorp/terraform-google-consul.git//modules/consul-cluster?ref=v0.4.0"

  gcp_project_id = var.gcp_project
  gcp_region = var.gcp_region

  cluster_name     = var.consul_server_cluster_name
  cluster_tag_name = var.consul_server_cluster_name
  cluster_size     = var.consul_server_cluster_size

  source_image = var.consul_server_source_image
  machine_type = var.consul_server_machine_type

  startup_script = data.template_file.startup_script_consul.rendered

  # WARNING!
  # In a production setting, we strongly recommend only launching a Consul Server cluster as private nodes.
  # Note that the only way to reach private nodes via SSH is to first SSH into another node that is not private.
  assign_public_ip_addresses = true

  allowed_inbound_tags_dns      = [var.nomad_server_cluster_name, var.nomad_client_cluster_name]
  allowed_inbound_tags_http_api = [var.nomad_server_cluster_name, var.nomad_client_cluster_name]
}

# This Startup Script will run at boot configure and start Consul on the Consul Server cluster nodes
data "template_file" "startup_script_consul" {
  template = file("${path.module}/startup-script-consul-server.sh")

  vars = {
    consul_server_cluster_tag_name = var.consul_server_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD CLIENT NODES
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-google-nomad.git//modules/nomad-cluster?ref=v0.0.1"
  source = "../../modules/nomad-cluster"

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
  allowed_inbound_tags_http        = [var.nomad_server_cluster_name, var.consul_server_cluster_name]
  allowed_inbound_tags_rpc         = [var.nomad_server_cluster_name]
  allowed_inbound_tags_serf        = [var.nomad_server_cluster_name]
}

# Render the Startup Script that will configure and run both Consul and Nomad in client mode.
data "template_file" "startup_script_nomad_client" {
  template = file("${path.module}/startup-script-nomad-client.sh")

  vars = {
    consul_server_cluster_tag_name = var.consul_server_cluster_name
  }
}
