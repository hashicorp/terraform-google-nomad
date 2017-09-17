# Nomad and Consul Co-located Cluster Example

This folder shows an example of Terraform code to deploy a [Nomad](https://www.nomadproject.io/) cluster co-located 
with a [Consul](https://www.consul.io/) cluster in [Google Cloud](https://cloud.google.com/) (if you want to run Nomad
and Consul on separate clusters, see the [nomad-consul-separate-cluster example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-separate-cluster) instead). The
cluster consists of two Manged Instance Groups: one with a small number of Nomad and Consul server nodes, which are
responsible for being part of the [consensus protocol](https://www.nomadproject.io/docs/internals/consensus.html), and
one with an arbitrary number of Nomad and Consul client nodes, which are used to run jobs:

![Nomad architecture](https://github.com/hashicorp/terraform-google-nomad/blob/master/_docs/architecture-nomad-consul-colocated.png?raw=true)

You will need to create a [Google Image](https://cloud.google.com/compute/docs/images) that has Nomad and Consul
installed, which you can do using the [nomad-consul-image example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-image)).  

For more info on how the Nomad cluster works, check out the [nomad-cluster](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/nomad-cluster) documentation.

## Quick start

To deploy a Nomad Cluster:

1. `git clone` this repo to your computer.
1. Build a Nomad and Consul Image. See the [nomad-consul-image example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-image) documentation for 
   instructions. Make sure to note down the name of the Image.
1. Install [Terraform](https://www.terraform.io/).
1. Make sure your local environment is authenticated to Google Cloud.
1. Open `variables.tf` and fill in any variables that don't have a default, including putting your Goolge Image ID into
   the `vault_source_image` and `consul_server_source_image` variables.
1. Run `terraform init`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
1. From the same directoy where you ran `terraform apply`, run the [nomad-examples-helper.sh script](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-examples-helper/nomad-examples-helper.sh)
   to print out the IP addresses of the Nomad servers and some example commands you can run to interact with the cluster:
   `../nomad-examples-helper/nomad-examples-helper.sh`.