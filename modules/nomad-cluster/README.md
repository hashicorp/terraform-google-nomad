# Nomad Cluster

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a 
[Nomad](https://www.nomadproject.io/) cluster in [Google Cloud](https://cloud.google.com/) on top of a [Managed Instance
Group](https://cloud.google.com/compute/docs/instance-groups/) module is designed to deploy a [Google Image](
https://cloud.google.com/compute/docs/images) that had Nomad installed via the [install-nomad](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) module in this Module.

Note that this module assumes you have a separate [Consul](https://www.consul.io/) cluster already running. If you want
to run Consul and Nomad in the same cluster, instead of using this module, see the [Deploy Nomad and Consul in the same 
cluster documentation](
https://github.com/hashicorp/terraform-google-nomad/tree/master/README.md#deploy-nomad-and-consul-in-the-same-cluster).



## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "nomad_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of the nomad-cluster module
  source = "github.com/hashicorp/terraform-google-nomad//modules/nomad-cluster?ref=v0.0.1"

  # Specify the name of the Nomad Google Image. You should build this using the scripts in the install-nomad module.
  source_image = "nomad-xxx"
  
  # Configure and start Nomad during boot. It will automatically connect to the Consul cluster specified in its 
  # configuration and form a cluster with other Nomad nodes connected to that Consul cluster. 
  startup_script = <<-EOF
              #!/bin/bash
              /opt/nomad/bin/run-nomad --server --num-servers 3
              EOF
  
  # ... See variables.tf for the other parameters you must define for the nomad-cluster module
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the nomad-cluster module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `source_image`: Use this parameter to specify the name of a Nomad [Google Image](
  https://cloud.google.com/compute/docs/images) to deploy on each server in the cluster. You should install Nomad in
  this Image using the scripts in the [install-nomad](
  https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) module.
  
* `startup_script`: Use this parameter to specify a [Startup Script](https://cloud.google.com/compute/docs/startupscript)
  that each server will run during boot. This is where you can use the [run-nomad script](
  https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/run-nomad) to configure and 
  run Nomad. The `run-nomad` script is one of the scripts installed by the [install-nomad](
  https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) module. 

You can find the other parameters in [variables.tf](variables.tf).

Check out the [nomad-consul-separate-cluster](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-separate-cluster) example for working
sample code. Note that if you want to run Nomad and Consul on the same cluster, see the [nomad-consul-colocated-cluster 
example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) example instead.


## Gotchas

We strongly recommend that you set `assign_public_ip_addresses` to `false` so that your Consul nodes are NOT addressable
from the public Internet. But running private nodes creates a few gotchas:

- **Configure Private Google Access.** By default, the Google Cloud API is queried over the public Internet, but private
  Compute Instances have no access to the public Internet so how do they query the Google API? Fortunately, Google 
  enables a Subnet property where you can [access Google APIs from within the network](
  https://cloud.google.com/compute/docs/private-google-access/configure-private-google-access) and not over the public
  Internet. **Setting this property is outside the scope of this module, but private Vault servers will not work unless
  this is enabled, or they have public Internet access.**

- **SSHing to private Compute Instances.** When a Compute Instance is private, you can only SSH into it from within the
  network. This module does not give you any direct way to SSH to the private Compute Instances, so you must separately
  setup a means to enter the network, for example, by setting up a public Bastion Host.

- **Internet access for private Compute Instances.** If you do want your private Compute Instances to have Internet 
  access, then Google recommends [setting up your own network proxy or NAT Gateway](
  https://cloud.google.com/compute/docs/vpc/special-configurations#proxyvm).  
  


## How do you connect to the Nomad cluster?

### Using the Node agent from your own computer

If you want to connect to the cluster from your own computer, [install 
Nomad](https://www.nomadproject.io/docs/install/index.html) and execute commands with the `-address` parameter set to
the IP address of one of the servers in your Nomad cluster. Note that this only works if the Nomad cluster Compute Instances
have public IP addresses (as in the case for the [root-example](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/root-example)), which is OK for testing and
experimentation, but NOT recommended for production usage.

To use the HTTP API, you first need to get the public IP address of one of the Nomad Instances. If you deployed the
[nomad-consul-colocated-cluster](https://github.com/hashicorp/terraform-google-nomad/tree/master/MAIN.md) or
[nomad-consul-separate-cluster](https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-consul-separate-cluster)
example, the [nomad-examples-helper.sh script](
https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/nomad-examples-helper/nomad-examples-helper.sh)
will do the tag lookup for you automatically (note, you must have the [Google Cloud SDK](https://cloud.google.com/sdk/), 
and the [Nomad agent](https://www.nomadproject.io/) installed locally):

```
> ../nomad-examples-helper/nomad-examples-helper.sh 

Your Nomad servers are running at the following IP addresses:

34.204.85.139
52.23.167.204
54.236.16.38
```

Copy and paste one of these IPs and use it with the `-address` argument for any [Nomad 
command](https://www.nomadproject.io/docs/commands/index.html). For example, to see the status of all the Nomad
servers:

```
> nomad server-members -address=http://<INSTANCE_IP_ADDR>:4646

ip-172-31-23-140.global  172.31.23.140  4648  alive   true    2         0.5.4  dc1         global
ip-172-31-23-141.global  172.31.23.141  4648  alive   true    2         0.5.4  dc1         global
ip-172-31-23-142.global  172.31.23.142  4648  alive   true    2         0.5.4  dc1         global
```

To see the status of all the Nomad agents:

```
> nomad node-status -address=http://<INSTANCE_IP_ADDR>:4646

ID        DC          Name                 Class   Drain  Status
ec2796cd  us-east-1e  i-0059e5cafb8103834  <none>  false  ready
ec2f799e  us-east-1d  i-0a5552c3c375e9ea0  <none>  false  ready
ec226624  us-east-1b  i-0d647981f5407ae32  <none>  false  ready
ec2d4635  us-east-1a  i-0c43dcc509e3d8bdf  <none>  false  ready
ec232ea5  us-east-1d  i-0eff2e6e5989f51c1  <none>  false  ready
ec2d4bd6  us-east-1c  i-01523bf946d98003e  <none>  false  ready
```

And to submit a job called `example.nomad`:
 
```
> nomad run -address=http://<INSTANCE_IP_ADDR>:4646 example.nomad

==> Monitoring evaluation "0d159869"
    Evaluation triggered by job "example"
    Allocation "5cbf23a1" created: node "1e1aa1e0", group "example"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "0d159869" finished with status "complete"
```



### Using the Nomad agent on another Compute Instance

For production usage, your Compute Instances should be running the [Nomad agent](
https://www.nomadproject.io/docs/agent/index.html). The agent nodes should discover the Nomad server nodes
automatically using Consul. Check out the [Service Discovery documentation](
https://www.nomadproject.io/docs/service-discovery/index.html) for details.




## What's included in this module?

This module creates the following architecture:

![Nomad architecture](https://github.com/hashicorp/terraform-google-nomad/blob/master/_docs/architecture.png?raw=true)

This architecture consists of the following resources:

* [Managed Instance Group](#managed-instance-group)
* [Firewall Rules](#firewall-rules)


### Managed Instance Group

This module runs Nomad on top of a single-zone [Managed Instance Group](https://cloud.google.com/compute/docs/instance-groups/). 
Typically, you should run the Instance Group with 3 or 5 Compute Instances spread across multiple [Zones](
https://cloud.google.com/compute/docs/regions-zones/regions-zones), but regrettably, Terraform Managed Instance Groups
[only support a single zone](https://github.com/terraform-providers/terraform-provider-google/issues/45). Each of the
Compute Instances should be running a Google Image that has had Nomad installed via the [install-nomad](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) module. You pass in the Google
Image name to run using the `source_image` input parameter.


### Firewall Rules

Network access to the Vault Compute Instances is governed by any VPC-level Firewall Rules, but in addition, this module
creates Firewall Rules to explicitly:
 
* Allow inbound HTTP (API) requests from the desired tags or CIDR blocks
* Allow inbound RPC requests from the desired tags or CIDR blocks
* Allow inbound serf requests from the desired tags or CIDR blocks


## How do you roll out updates?

Unfortunately, this remains an open item. Unlike Amazon Web Services, Google Cloud does not allow you to control the
manner in which Compute Instances in a Managed Instance Group are updated, except that you can specify that either
all Instances should be immediately restarted when a Managed Instance Group's Instance Template is updated (by setting
the [update_strategy](https://www.terraform.io/docs/providers/google/r/compute_instance_group_manager.html#update_strategy)
of the Managed Instance Group to `RESTART`), or that nothing at all should happen (by setting the update_strategy to 
`NONE`).

While updating Consul, we must be mindful of always preserving a [quorum](https://www.consul.io/docs/guides/servers.html#removing-servers),
but neither of the above options enables a safe update. While updating Nomad, we need the ability to terminate one 
Compute Instance at a time to avoid down time.

One possible option may be the use of GCP's [Rolling Updates Feature](https://cloud.google.com/compute/docs/instance-groups/updating-managed-instance-groups)
however this feature remains in Alpha and may not necessarily support our use case.

The most likely solution will involve writing a script that makes use of the [abandon-instances](
https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/abandon-instances) and [resize](
https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/resize) GCP API calls. Using
these primitives, we can "abandon" Compute Instances from a Compute Instance Group (thereby removing them from the Group
but leaving them otherwise untouched), manually add new Instances based on an updated Instance Template that will 
automatically join the Consul cluster, make Consul API calls to our abandoned Instances to leave the Group, validate
that all new Instances are members of the cluster and then manually terminate the abandoned Instances.  

For now, you can perform this process manually, but needless to say, PRs that automate this are welcome!





## What happens if a node crashes?

There are two ways a Nomad node may go down:
 
1. The Nomad process may crash. In that case, `supervisor` should restart it automatically.
1. The Compute Instance running Nomad dies.  In that case, the Managed Instance Group will launch a replacement automatically.  
   Note that in this case, since the Nomad agent did not exit gracefully, and the replacement will have a different ID,
   you may have to manually clean out the old nodes using the [server-force-leave
   command](https://www.nomadproject.io/docs/commands/server-force-leave.html). We may add a script to do this 
   automatically in the future. For more info, see the [Nomad Outage 
   documentation](https://www.nomadproject.io/guides/outage.html).





## Security

Here are some of the main security considerations to keep in mind when using this module:

1. [Encryption in transit](#encryption-in-transit)
1. [Encryption at rest](#encryption-at-rest)
1. [Dedicated instances](#dedicated-instances)
1. [Security groups](#security-groups)
1. [SSH access](#ssh-access)


### Encryption in transit

Nomad can encrypt all of its network traffic. For instructions on enabling network encryption, have a look at the
[How do you handle encryption documentation](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/run-nomad#how-do-you-handle-encryption).


### Encryption at rest

The Compute Instances in the cluster store all their data on the root disk volume. By default, [GCE encrypts all data at
rest](https://cloud.google.com/compute/docs/disks/customer-supplied-encryption), a process managed by GCE without any
additional actions needed on your part. You can also provide your own encryption keys and GCE will use these to protect
the Google-generated keys used to encrypt and decrypt your data.


### Firewall Rules

This module creates Firewall Rules that explicitly permit the minimum ports necessary for the Vault cluster to function.
See the Firewall Rules section above for details.
  

### SSH access

You can SSH to the Compute Instances using the [conventional methods offered by GCE](
https://cloud.google.com/compute/docs/instances/connecting-to-instance). Google [strongly recommends](
https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys) that you connect to an Instance [from your web
browser](https://cloud.google.com/compute/docs/instances/connecting-to-instance#sshinbrowser) or using the [gcloud
command line tool](https://cloud.google.com/compute/docs/instances/connecting-to-instance#sshingcloud).

If you must manually manage your SSH keys, use the `custom_metadata` property to specify accepted SSH keys in the format
required by GCE. 






## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own:

* [Consul](#consul)
* [Monitoring, alerting, log aggregation](#monitoring-alerting-log-aggregation)
* [VPCs, subnets, route tables](#vpcs-subnetworks-route-tables)
* [DNS entries](#dns-entries)


### Consul

This module assumes you already have Consul deployed in a separate cluster. If you want to run Nomad and Consul on the
same cluster, instead of using this module, see the [Deploy Nomad and Consul in the same cluster 
documentation](https://github.com/hashicorp/terraform-google-nomad/tree/master/README.md#deploy-nomad-and-consul-in-the-same-cluster).


### Monitoring, alerting, log aggregation

This module does not include anything for monitoring, alerting, or log aggregation. All Compute Instance Groups and 
Compute Instances come with the option to use [Google StackDriver](https://cloud.google.com/stackdriver/), GCP's
monitoring, logging, and diagnostics platform that works with both GCP and AWS.

If you wish to install the StackDriver monitoring agent or logging agent, pass the desired installation instructions to
the `startup_script` property.


### VPCs, subnetworks, route tables

This module assumes you've already created your network topology (VPC, subnetworks, route tables, etc). You will need to 
pass in the the relevant info about your network topology (e.g. `vpc_id`, `subnet_ids`) as input variables to this 
module, or just use the default network topology created by GCP.


### DNS entries

This module does not create any DNS entries for Nomad (e.g. with Cloud DNS).


