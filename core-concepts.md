# Background

To run a Nomad cluster, you need to deploy a small number of server nodes (typically 3), which are responsible
for being part of the [consensus protocol](https://www.nomadproject.io/docs/internals/consensus.html), and a larger
number of client nodes, which are used for running jobs. You must also have a [Consul](https://www.consul.io/) cluster
deployed (see the [Consul GCP Module](https://github.com/hashicorp/terraform-google-consul)) in one of the following
configurations:

1. [Deploy Nomad and Consul in the same cluster](#deploy-nomad-and-consul-in-the-same-cluster)
1. [Deploy Nomad and Consul in separate clusters](#deploy-nomad-and-consul-in-separate-clusters)


### Deploy Nomad and Consul in the same cluster

1. Use the [install-consul module](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/install-consul)
   from the Consul GCP Module and the [install-nomad module](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) from this Module in a Packer
   template to create a Google Image with Consul and Nomad.

   Ideally, we would publish a "public" image you can use for trail purposes, but Google Cloud does not yet support
   custom public Images so, for now, you must build your own Google Image to use this module.

1. Deploy a small number of server nodes (typically, 3) using the [consul-cluster
   module](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/consul-cluster). Execute the
   [run-consul script](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/run-consul) and the
   [run-nomad script](https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/run-nomad) on each node
   during boot, setting the `--server` flag in both scripts.

1. Deploy as many client nodes as you need using the [nomad-cluster module](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/nomad-cluster). Execute the [run-consul script](
   https://github.com/hashicorp/terraform-googe-consul/tree/master/modules/run-consul) and the [run-nomad script](
   https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) on each node during boot, setting the
   `--client` flag in both scripts.

Check out the [nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/root-example)
for working sample code.


### Deploy Nomad and Consul in separate clusters

1. Deploy a standalone Consul cluster by following the instructions in the [Consul GCP Module](
   https://github.com/hashicorp/terraform-google-consul).

1. Use the scripts from the [install-nomad module](https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad)
   in a Packer template to create a Google Image with Nomad installed.

1. Deploy a small number of server nodes (typically, 3) using the [nomad-cluster module](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/nomad). Execute the [run-nomad script](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/run-nomad) on each node during boot, setting
   the `--server` flag. You will need to configure each node with the connection details for your standalone Consul cluster.

1. Deploy as many client nodes as you need using the [nomad-cluster module](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/nomad). Execute the [run-nomad script](
   https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/run-nomad) on each node during boot, setting
   the `--client` flag.

Check out the [nomad-consul-separate-cluster example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-separate-cluster) for working sample code.
