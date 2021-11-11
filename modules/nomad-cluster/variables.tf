# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_region" {
  description = "All GCP resources will be launched in this Region."
  type        = string
}

variable "cluster_name" {
  description = "The name of the Nomad cluster (e.g. nomad-stage). This variable is used to namespace all resources created by this module."
  type        = string
}

variable "cluster_tag_name" {
  description = "The tag name the Compute Instances will look for to automatically discover each other and form a cluster. TIP: If running more than one Nomad cluster, each cluster should have its own unique tag name."
  type        = string
}

variable "machine_type" {
  description = "The machine type of the Compute Instance to run for each node in the cluster (e.g. n1-standard-1)."
  type        = string
}

variable "cluster_size" {
  description = "The number of nodes to have in the Nomad cluster. We strongly recommended that you use either 3 or 5."
  type        = number
}

variable "source_image" {
  description = "The source image used to create the boot disk for a Vault node. Only images based on Ubuntu 16.04 or 18.04 LTS are supported at this time."
  type        = string
}

variable "startup_script" {
  description = "A Startup Script to execute when the server first boots. We recommend passing in a bash script that executes the run-vault script, which should have been installed in the Vault Google Image by the install-vault module."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_group_target_pools" {
  description = "To use a Load Balancer with the Consul cluster, you must populate this value. Specifically, this is the list of Target Pool URLs to which new Compute Instances in the Instance Group created by this module will be added. Note that updating the Target Pools attribute does not affect existing Compute Instances."
  type        = list(string)
  default     = []
}

variable "cluster_description" {
  description = "A description of the Vault cluster; it will be added to the Compute Instance Template."
  type        = string
  default     = null
}

variable "assign_public_ip_addresses" {
  description = "If true, each of the Compute Instances will receive a public IP address and be reachable from the Public Internet (if Firewall rules permit). If false, the Compute Instances will have private IP addresses only. In production, this should be set to false."
  type        = bool
  default     = false
}

variable "network_name" {
  description = "The name of the VPC Network where all resources should be created."
  type        = string
  default     = "default"
}

variable "custom_tags" {
  description = "A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module."
  type        = list(string)
  default     = []
}

variable "instance_group_update_strategy" {
  description = "The update strategy to be used by the Instance Group. IMPORTANT! When you update almost any cluster setting, under the hood, this module creates a new Instance Group Template. Once that Instance Group Template is created, the value of this variable determines how the new Template will be rolled out across the Instance Group. Unfortunately, as of August 2017, Google only supports the options 'RESTART' (instantly restart all Compute Instances and launch new ones from the new Template) or 'NONE' (do nothing; updates should be handled manually). Google does offer a rolling updates feature that perfectly meets our needs, but this is in Alpha (https://goo.gl/MC3mfc). Therefore, until this module supports a built-in rolling update strategy, we recommend using `NONE` and either using the alpha rolling updates strategy to roll out new Vault versions, or to script this using GCE API calls. If using the alpha feature, be sure you are comfortable with the level of risk you are taking on. For additional detail, see https://goo.gl/hGH6dd."
  type        = string
  default     = "NONE"
}

# Metadata

variable "metadata_key_name_for_cluster_size" {
  description = "The key name to be used for the custom metadata attribute that represents the size of the Nomad cluster."
  type        = string
  default     = "cluster-size"
}

variable "custom_metadata" {
  description = "A map of metadata key value pairs to assign to the Compute Instance metadata."
  type        = map(string)
  default     = {}
}

# Firewall Ports

variable "http_port" {
  description = "The port used by Nomad to handle incoming HTPT (API) requests."
  type        = number
  default     = 4646
}

variable "rpc_port" {
  description = "The port used by Nomad to handle incoming RPC requests."
  type        = number
  default     = 4647
}

variable "serf_port" {
  description = "The port used by Nomad to handle incoming serf requests."
  type        = number
  default     = 4648
}

variable "allowed_inbound_cidr_blocks_http" {
  description = "A list of CIDR-formatted IP address ranges from which the Compute Instances will allow connections to Nomad on the port specified by var.http_port."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_tags_http" {
  description = "A list of tags from which the Compute Instances will allow connections to Nomad on the port specified by var.http_port."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_cidr_blocks_rpc" {
  description = "A list of CIDR-formatted IP address ranges from which the Compute Instances will allow connections to Nomad on the port specified by var.rpc_port."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_tags_rpc" {
  description = "A list of tags from which the Compute Instances will allow connections to Nomad on the port specified by var.rpc_port."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_cidr_blocks_serf" {
  description = "A list of CIDR-formatted IP address ranges from which the Compute Instances will allow connections to Nomad on the port specified by var.serf_port."
  type        = list(string)
  default     = []
}

variable "allowed_inbound_tags_serf" {
  description = "A list of tags from which the Compute Instances will allow connections to Nomad on the port specified by var.serf_port."
  type        = list(string)
  default     = []
}

# Disk Settings

variable "root_volume_disk_size_gb" {
  description = "The size, in GB, of the root disk volume on each Consul node."
  type        = number
  default     = 30
}

variable "root_volume_disk_type" {
  description = "The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard"
  type        = string
  default     = "pd-standard"
}

# Update Policy

variable "instance_group_update_policy_type" {
  description = "The type of update process. You can specify either PROACTIVE so that the instance group manager proactively executes actions in order to bring instances to their target versions or OPPORTUNISTIC so that no action is proactively executed but the update will be performed as part of other actions (for example, resizes or recreateInstances calls)."
  type        = string
  default     = "PROACTIVE"
}

variable "instance_group_update_policy_redistribution_type" {
  description = "The instance redistribution policy for regional managed instance groups. Valid values are: 'PROACTIVE' and 'NONE'. If 'PROACTIVE', the group attempts to maintain an even distribution of VM instances across zones in the region. If 'NONE', proactive redistribution is disabled."
  type        = string
  default     = "PROACTIVE"
}

variable "instance_group_update_policy_minimal_action" {
  description = "Minimal action to be taken on an instance. You can specify either 'RESTART' to restart existing instances or 'REPLACE' to delete and create new instances from the target template. If you specify a 'RESTART', the Updater will attempt to perform that action only. However, if the Updater determines that the minimal action you specify is not enough to perform the update, it might perform a more disruptive action."
  type        = string
  default     = "REPLACE"
}

variable "instance_group_update_policy_max_surge_fixed" {
  description = "The maximum number of instances that can be created above the specified targetSize during the update process. Conflicts with var.instance_group_update_policy_max_surge_percent. See https://www.terraform.io/docs/providers/google/r/compute_region_instance_group_manager.html#max_surge_fixed for more information."
  type        = number
  default     = 3
}

variable "instance_group_update_policy_max_surge_percent" {
  description = "The maximum number of instances(calculated as percentage) that can be created above the specified targetSize during the update process. Conflicts with var.instance_group_update_policy_max_surge_fixed. Only allowed for regional managed instance groups with size at least 10."
  type        = number
  default     = null
}

variable "instance_group_update_policy_max_unavailable_fixed" {
  description = "The maximum number of instances that can be unavailable during the update process. Conflicts with var.instance_group_update_policy_max_unavailable_percent. It has to be either 0 or at least equal to the number of zones. If fixed values are used, at least one of var.instance_group_update_policy_max_unavailable_fixed or var.instance_group_update_policy_max_surge_fixed must be greater than 0."
  type        = number
  default     = 0
}

variable "instance_group_update_policy_max_unavailable_percent" {
  description = "The maximum number of instances(calculated as percentage) that can be unavailable during the update process. Conflicts with var.instance_group_update_policy_max_unavailable_fixed. Only allowed for regional managed instance groups with size at least 10."
  type        = number
  default     = null
}

variable "instance_group_update_policy_min_ready_sec" {
  description = "Minimum number of seconds to wait for after a newly created instance becomes available. This value must be between 0-3600."
  type        = number
  default     = 300
}
