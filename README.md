# Elasticsearch Azure Marketplace offering

This repository consists of:

* [src/mainTemplate.json](src/mainTemplate.json) - Entry Azure Resource Management (ARM) template.
* [src/createUiDefinition](src/createUiDefinition.json) - UI definition file for our market place offering. This file produces an output json that the ARM template can accept as input parameters JSON.


## Marketplace

TODO gif that shows how to find us on the azure market place and screenshot of steps.

You can view the UI in developer mode by [clicking here](https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fraw.githubusercontent.com%2FMpdreamz%2FARM-Templates%2Fmaster%2Fsrc%2FcreateUiDefinition.json"}}). If you feel something is cached improperly use [this client unoptimized link instead](https://portal.azure.com/?clientOptimizations=false#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fraw.githubusercontent.com%2FMpdreamz%2FARM-Templates%2Fmaster%2Fsrc%2FcreateUiDefinition.json"}})

## ARM template

<table>
  <th><td>Parameter</td><td>Type</td><td>Description</td></th>
  <tr><td>esVersion</td><td>enum</td>
    <td>A valid supported Elasticsearch version
    </td></tr>
  <tr><td>esClusterName</td><td>string</td>
    <td> The name of the Elasticsearch cluster
    </td></tr>

  <tr><td>loadBalancerType</td><td>string</td>
    <td>Whether the loadbalancer should be `internal` or `external`.
    If you run `external` you should also install the shield plugin and look into setting up SSL on your endpoint
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
    </td></tr>

  <tr><td>esClusterName</td><td>string</td>
    <td>
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
