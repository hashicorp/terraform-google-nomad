# Nomad Firewall Rules Module

This folder contains a [Terraform](https://www.terraform.io/) module that defines the Firewall Rules used by a 
[Nomad](https://www.nomadproject.io/) cluster to control the traffic that is allowed to go in and out of the cluster. 

Normally, you'd get these rules by default if you're using the [nomad-cluster module](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-cluster), but if 
you're running Nomad on top of a different cluster, then you can use this module to add the necessary Firewall Rules 
rules that cluster needs. For example, imagine you were using the [consul-cluster 
module](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/consul-cluster) to run a cluster of 
servers that have both Nomad and Consul on each node:

```hcl
module "consul_servers" {
  source = "git::git@github.com:hashicorp/terraform-google-consul.git//modules/consul-cluster?ref=v0.0.1"
  
  # This Image has both Nomad and Consul installed
  source_image = "nomad-consul-xyz123"
}
```

The `consul-cluster` module will provide the Firewall Rules for Consul, but not for Nomad. To ensure those 
servers have the necessary ports open for using Nomad, you can use this module as follows:


```hcl
module "security_group_rules" {
  source = "git::git@github.com:hashicorp/terraform-google-nomad.git//modules/nomad-firewall-rules?ref=v0.0.1"

  cluster_name = "${module.consul_servers.cluster_name}"
  cluster_tag_name = "${module.consul_servers.cluster_tag_name}"
  
  # ... (other params omitted) ...
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of this module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `cluster_name`: Use this parameter to specify the name of the cluster for which these Firewall Rules will apply; this
  allows us to name these resources in an intuitive way.

* `cluster_tag_name`: Use this parameter to indicate the cluster to which these Firewall Rules should apply.
  
You can find the other parameters in [variables.tf](variables.tf).

Check out the [nomad-consul-colocated-cluster example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/root-example) for working sample code.