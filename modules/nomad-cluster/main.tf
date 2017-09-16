# ---------------------------------------------------------------------------------------------------------------------
# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.10.3 AND ABOVE
# This way we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.10.3"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A GCE MANAGED INSTANCE GROUP TO RUN NOMAD
# Ideally, we would run a "regional" Managed Instance Group that spans many Zones, but the Terraform GCP provider has
# not yet implemented https://github.com/terraform-providers/terraform-provider-google/issues/45, so we settle for a
# single-zone Managed Instance Group.
# ---------------------------------------------------------------------------------------------------------------------

# Create the single-zone Managed Instance Group where Nomad will run.
resource "google_compute_instance_group_manager" "nomad" {
  name = "${var.cluster_name}-ig"

  base_instance_name = "${var.cluster_name}"
  instance_template  = "${data.template_file.compute_instance_template_self_link.rendered}"
  zone               = "${var.gcp_zone}"

  # Restarting all Nomad servers at the same time will result in data loss and down time. Therefore, the update strategy
  # used to roll out a new GCE Instance Template must be a rolling update. But since Terraform does not yet support
  # ROLLING_UPDATE, such updates must be manually rolled out for now.
  update_strategy = "${var.instance_group_update_strategy}"

  target_pools = ["${var.instance_group_target_pools}"]
  target_size  = "${var.cluster_size}"

  depends_on = ["google_compute_instance_template.nomad_public", "google_compute_instance_template.nomad_private"]
}

# Create the Instance Template that will be used to populate the Managed Instance Group.
# NOTE: This Compute Instance Template is only created if var.assign_public_ip_addresses is true.
resource "google_compute_instance_template" "nomad_public" {
  count = "${var.assign_public_ip_addresses}"

  name_prefix = "${var.cluster_name}"
  description = "${var.cluster_description}"

  instance_description = "${var.cluster_description}"
  machine_type         = "${var.machine_type}"

  tags = "${concat(list(var.cluster_tag_name), var.custom_tags)}"
  metadata_startup_script = "${var.startup_script}"
  metadata = "${merge(map(var.metadata_key_name_for_cluster_size, var.cluster_size), var.custom_metadata)}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible = false
  }

  disk {
    boot         = true
    auto_delete  = true
    source_image = "${var.source_image}"
    disk_size_gb = "${var.root_volume_disk_size_gb}"
    disk_type    = "${var.root_volume_disk_type}"
  }

  network_interface {
    network = "${var.network_name}"
    access_config {
      # The presence of this property assigns a public IP address to each Compute Instance. We intentionally leave it
      # blank so that an external IP address is selected automatically.
      nat_ip = ""
    }
  }

  # For a full list of oAuth 2.0 Scopes, see https://developers.google.com/identity/protocols/googlescopes
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/compute.readonly",
    ]
  }

  # Per Terraform Docs (https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#using-with-instance-group-manager),
  # we need to create a new instance template before we can destroy the old one. Note that any Terraform resource on
  # which this Terraform resource depends will also need this lifecycle statement.
  lifecycle {
    create_before_destroy = true
  }
}

# Create the Instance Template that will be used to populate the Managed Instance Group.
# NOTE: This Compute Instance Template is only created if var.assign_public_ip_addresses is false.
resource "google_compute_instance_template" "nomad_private" {
  count = "${1 - var.assign_public_ip_addresses}"

  name_prefix = "${var.cluster_name}"
  description = "${var.cluster_description}"

  instance_description = "${var.cluster_description}"
  machine_type = "${var.machine_type}"

  tags = "${concat(list(var.cluster_tag_name), var.custom_tags)}"
  metadata_startup_script = "${var.startup_script}"
  metadata = "${merge(map(var.metadata_key_name_for_cluster_size, var.cluster_size), var.custom_metadata)}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible = false
  }

  disk {
    boot         = true
    auto_delete  = true
    source_image = "${var.source_image}"
  }

  network_interface {
    network = "${var.network_name}"
  }

  # For a full list of oAuth 2.0 Scopes, see https://developers.google.com/identity/protocols/googlescopes
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/compute.readonly",
    ]
  }

  # Per Terraform Docs (https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#using-with-instance-group-manager),
  # we need to create a new instance template before we can destroy the old one. Note that any Terraform resource on
  # which this Terraform resource depends will also need this lifecycle statement.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE FIREWALL RULES
# - These Firewall Rules may be redundant depending on the settings of your VPC Network, but if your Network is locked
#   down, these Rules will open up the appropriate ports.
# - Note that public access to your Nomad cluster will only be permitted if var.assign_public_ip_addresses is true.
# - Each Firewall Rule is only created if at least one source tag or source CIDR block for that Firewall Rule is specified.
# ---------------------------------------------------------------------------------------------------------------------

# Specify which traffic is allowed into the Nomad cluster for inbound HTTP requests
resource "google_compute_firewall" "allow_inbound_http" {
  count = "${length(var.allowed_inbound_cidr_blocks_http) + length(var.allowed_inbound_tags_http) > 0 ? 1 : 0}"

  name    = "${var.cluster_name}-rule-external-http-access"
  network = "${var.network_name}"

  allow {
    protocol = "tcp"
    ports    = [
      "${var.http_port}",
    ]
  }

  source_ranges = "${var.allowed_inbound_cidr_blocks_http}"
  source_tags = "${var.allowed_inbound_tags_http}"
  target_tags = ["${var.cluster_tag_name}"]
}

# Specify which traffic is allowed into the Nomad cluster for inbound RPC requests
resource "google_compute_firewall" "allow_inbound_rpc" {
  count = "${length(var.allowed_inbound_cidr_blocks_rpc) + length(var.allowed_inbound_tags_rpc) > 0 ? 1 : 0}"

  name    = "${var.cluster_name}-rule-external-rpc-access"
  network = "${var.network_name}"

  allow {
    protocol = "tcp"
    ports    = [
      "${var.rpc_port}",
    ]
  }

  source_ranges = "${var.allowed_inbound_cidr_blocks_rpc}"
  source_tags = "${var.allowed_inbound_tags_rpc}"
  target_tags = ["${var.cluster_tag_name}"]
}

# Specify which traffic is allowed into the Nomad cluster for inbound serf requests
resource "google_compute_firewall" "allow_inbound_serf" {
  count = "${length(var.allowed_inbound_cidr_blocks_serf) + length(var.allowed_inbound_tags_serf) > 0 ? 1 : 0}"

  name    = "${var.cluster_name}-rule-external-serf-access"
  network = "${var.network_name}"

  allow {
    protocol = "tcp"
    ports    = [
      "${var.serf_port}",
    ]
  }

  allow {
    protocol = "udp"
    ports    = [
      "${var.serf_port}",
    ]
  }

  source_ranges = "${var.allowed_inbound_cidr_blocks_serf}"
  source_tags = "${var.allowed_inbound_tags_serf}"
  target_tags = ["${var.cluster_tag_name}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CONVENIENCE VARIABLES
# Because we've got some conditional logic in this template, some values will depend on our properties. This section
# wraps such values in a nicer construct.
# ---------------------------------------------------------------------------------------------------------------------

# The Google Compute Instance Group needs the self_link of the Compute Instance Template that's actually created.
data "template_file" "compute_instance_template_self_link" {
  # This will return the self_link of the Compute Instance Template that is actually created. It works as follows:
  # - Make a list of 1 value or 0 values for each of google_compute_instance_template.consul_servers_public and
  #   google_compute_instance_template.consul_servers_private by adding the glob (*) notation. Terraform will complain
  #   if we directly reference a resource property that doesn't exist, but it will permit us to turn a single resource
  #   into a list of 1 resource and "no resource" into an empty list.
  # - Concat these lists. concat(list-of-1-value, empty-list) == list-of-1-value
  # - Take the first element of list-of-1-value
  template = "${element(concat(google_compute_instance_template.nomad_public.*.self_link, google_compute_instance_template.nomad_private.*.self_link), 0)}"
}