output "gcp_project" {
  value = var.gcp_project
}

output "gcp_region" {
  value = var.gcp_region
}

output "nomad_server_cluster_size" {
  value = var.nomad_consul_server_cluster_size
}

output "nomad_client_cluster_size" {
  value = var.nomad_client_cluster_size
}

output "nomad_server_cluster_tag_name" {
  value = var.nomad_consul_server_cluster_name
}

output "nomad_client_cluster_tag_name" {
  value = var.nomad_client_cluster_name
}

output "nomad_server_instance_group_name" {
  value = module.nomad_and_consul_servers.instance_group_name
}

output "nomad_server_instance_group_url" {
  value = module.nomad_and_consul_servers.instance_group_url
}

output "nomad_client_instance_group_id" {
  value = module.nomad_clients.instance_group_id
}

output "nomad_client_instance_group_name" {
  value = module.nomad_clients.instance_group_name
}

output "nomad_client_instance_group_url" {
  value = module.nomad_clients.instance_group_url
}
