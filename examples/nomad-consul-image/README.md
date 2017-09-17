# Nomad and Consul Google Image

This folder shows an example of how to use the [install-nomad module](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) from this Module and 
the [install-consul module](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/install-consul)
from the Consul GCP Module with [Packer](https://www.packer.io/) to create [Google Images ](
https://cloud.google.com/compute/docs/images) that have Nomad and Consul installed on top of Ubuntu 16.04. 

These Images will have [Consul](https://www.consul.io/) and [Nomad](https://www.nomadproject.io/) installed and 
configured to automatically join a cluster during boot-up.

To see how to deploy this Image, check out the [nomad-consul-colocated-cluster 
example](https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/root-example). For more info on Nomad
installation and configuration, check out the [install-nomad](
https://github.com/hashicorp/terraform-google-nomad/tree/master/modules/install-nomad) documentation.



## Quick start

To build the Nomad and Consul Image:

1. `git clone` this repo to your computer.

1. Install [Packer](https://www.packer.io/).

1. Configure your environment's Google credentials using the [Google Cloud SDK](https://cloud.google.com/sdk/).

1. Update the `variables` section of the `nomad-consul.json` Packer template to configure the Project ID, Google Cloud Zone, 
   and Consul and Nomad versions you wish to use.
   
1. Run `packer build nomad-consul.json`.

When the build finishes, it will output the name of the new Google Image. To see how to deploy this Image, check out the 
[nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-google-nomad/tree/master/examples/root-example/README.md).




## Creating your own Packer template for production usage

When creating your own Packer template for production usage, you can copy the example in this folder more or less 
exactly, except for one change: we recommend replacing the `file` provisioner with a call to `git clone` in the `shell` 
provisioner. Instead of:

```json
{
  "provisioners": [{
    "type": "file",
    "source": "{{template_dir}}/../../../terraform-google-nomad",
    "destination": "/tmp"
  },{
    "type": "shell",
    "inline": [
      "/tmp/terraform-google-nomad/modules/install-nomad/install-nomad --version {{user `nomad_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

Your code should look more like this:

```json
{
  "provisioners": [{
    "type": "shell",
    "inline": [
      "git clone --branch <module_VERSION> https://github.com/hashicorp/terraform-google-nomad.git /tmp/terraform-google-nomad",
      "/tmp/terraform-google-nomad/modules/install-nomad/install-nomad --version {{user `nomad_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

You should replace `<module_VERSION>` in the code above with the version of this module that you want to use (see
the [Releases Page](../../releases) for all available versions). That's because for production usage, you should always
use a fixed, known version of this Module, downloaded from the official Git repo. On the other hand, when you're 
just experimenting with the Module, it's OK to use a local checkout of the Module, uploaded from your own 
computer.