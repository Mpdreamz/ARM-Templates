# Elasticsearch Azure Marketplace offering

This repository consists of:

* [src/mainTemplate.json](src/mainTemplate.json) - Entry Azure Resource Management (ARM) template.
* [src/createUiDefinition](src/createUiDefinition.json) - UI definition file for our market place offering. This file produces an output json that the ARM template can accept as input parameters JSON.


## Marketplace

TODO gif that shows how to find us on the azure market place and screenshot of steps.

You can view the UI in developer mode by [clicking here](https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fraw.githubusercontent.com%2FMpdreamz%2FARM-Templates%2Fmaster%2Fsrc%2FcreateUiDefinition.json"}}). If you feel something is cached improperly use [this client unoptimized link instead](https://portal.azure.com/?clientOptimizations=false#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fraw.githubusercontent.com%2FMpdreamz%2FARM-Templates%2Fmaster%2Fsrc%2FcreateUiDefinition.json"}})

## ARM template

<table>
  <tr><th>Parameter</td><th>Type</th><th>Description</th></tr>
  <tr><td>esVersion</td><td>enum</td>
    <td>A valid supported Elasticsearch version see [this list for supported versions](https://github.com/Mpdreamz/ARM-Templates/blob/master/src/mainTemplate.json#L8)
    </td></tr>
  <tr><td>esClusterName</td><td>string</td>
    <td> The name of the Elasticsearch cluster
    </td></tr>

  <tr><td>loadBalancerType</td><td>string</td>
    <td>Whether the loadbalancer should be `internal` or `external`.
    If you run `external` you should also install the shield plugin and look into setting up SSL on your endpoint
    </td></tr>

  <tr><td>esPlugins</td><td>string</td>
    <td>Either `Yes` or `No`, whether to install the elasticsearch suite of
    plugins (Shield, Watcher, Marvel)
    </td></tr>

  <tr><td>kibana</td><td>string</td>
    <td>Either `Yes` or `No`, provision an extra machine with a public IP that
    has Kibana installed on it. If you have opted to also install the Elasticsearch plugins using `esPlugins` then the Marvel and Sense Kibana apps get installed as well.
    </td></tr>

  <tr><td>jumpbox</td><td>string</td>
    <td>Either `Yes` or `No`, Optionally add a virtual machine to the deployment which you can use to connect and manage virtual machines on the internal network.
    </td></tr>

  <tr><td>vmSizeDataNodes</td><td>string</td>
    <td>Azure VM size of the data nodes see [this list for supported sizes](https://github.com/Mpdreamz/ARM-Templates/blob/master/src/mainTemplate.json#L69)
    </td></tr>

  <tr><td>vmDataNodeCount</td><td>int</td>
    <td>The number of data nodes you wish to deploy. Should be greater than 0.
    </td></tr>

  <tr><td>dataNodesAreMasterEligible</td><td>string</td>
    <td>Either `Yes` or `No`, Make all data nodes master eligible, this can be useful for small Elasticsearch clusters. When `Yes` no dedicated master nodes will be provisioned
    </td></tr>

  <tr><td>vmSizeMasterNodes</td><td>string</td>
    <td>Azure VM size of the master nodes see [this list for supported sizes](https://github.com/Mpdreamz/ARM-Templates/blob/master/src/mainTemplate.json#L69). By default the template deploys 3 dedicated master nodes, unless `dataNodesAreMasterEligible` is set to `Yes`
    </td></tr>

  <tr><td>vmClientNodeCount</td><td>int</td>
    <td> The number of client nodes to provision. Defaults 0 and can be any positive integer. By default the data nodes are directly exposed on the loadbalancer. If you provision client nodes, only these will be added to the loadbalancer.
    </td></tr>

  <tr><td>vmSizeClientNodes</td><td>string</td>
    <td> Azure VM size of the client nodes see [this list for supported sizes](https://github.com/Mpdreamz/ARM-Templates/blob/master/src/mainTemplate.json#L69).
    </td></tr>

  <tr><td>adminUsername</td><td>string</td>
    <td>Admin username used when provisioning virtual machines
    </td></tr>

  <tr><td>password</td><td>object</td>
    <td>
    </td></tr>

  <tr><td>shieldAdminPassword</td><td>securestring</td>
    <td>Shield password for the `es_admin` user with admin role, must be &gt; 6 characters
    </td></tr>

  <tr><td>shieldReadPassword</td><td>securestring</td>
    <td>Shield password for the `es_read` user with user (read-only) role, must be &gt; 6 characters
    </td></tr>

  <tr><td>shieldKibanaPassword</td><td>securestring</td>
    <td>Shield password for the `es_kibana` user with kibana4 role, must be &gt; 6 characters
    </td></tr>

  <tr><td>location</td><td>string</td>
    <td>The location where to provision all the items in this template. Defaults to the special `ResourceGroup` value which means it will inherit the location
    from the resource group see [this list for supported locations](https://github.com/Mpdreamz/ARM-Templates/blob/master/src/mainTemplate.json#L197).
    </td></tr>

</table>

### Command line

first make sure you are logged into azure

```shell
$ azure login
```

Then make sure you are in arm mode

```shell
$ azure config mode arm
```

Then create a resource group `<name>` in a `<location>` (e.g `westeurope`) where we can deploy too

```shell
$ azure group create <name> <location>
```

Next we can either use our published template directly using `--template-uri`

> $ azure group deployment create --template-uri https://raw.githubusercontent.com/Mpdreamz/ARM-Templates/master/src/mainTemplate.json --parameters-file parameters/password.parameters.json -g <name>

or if your are executing commands from a clone of this repo using `--template-file`

> $ azure group deployment create --template-file src/mainTemplate.json --parameters-file parameters/password.parameters.json -g <name>

`<name>` in these last two examples refers to the resource group you just created.

**NOTE**

The `--parameters-file` can specify a different location for the items that get provisioned inside of the resource group. Make sure these are the same prior to deploying if you need them to be.

### Web based

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMpdreamz%2FARM-Templates%2Fmaster%2Fsrc%2FmainTemplate.json" target="_blank">
   <img alt="Deploy to Azure" src="http://azuredeploy.net/deploybutton.png"/>
