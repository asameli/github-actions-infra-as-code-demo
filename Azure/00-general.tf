##############################################################################################################
#
# Fortinet
# Infrastructure As Code Demo
# GitHub Actions - Terraform Cloud
#
##############################################################################################################
#
#
# Variables during deployment the first 4 (PREFIX, LOCATION, USERNAME, PASSWORD) are mandatory
#
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {
}

variable "PASSWORD" {
}

variable "FLEXVM_API_USERNAME" {
}

variable "FLEXVM_API_PASSWORD" {
}
##############################################################################################################
# FortiGate license type
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_20190624') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FGT_BYOL_FLEXVM_LICENSE_FILE" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "FGT_ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0.0"
    }
    fortiflexvm = {
      version = "2.0.0"
      source  = "fortinetdev/fortiflexvm"
    }
  }

  backend "remote" {
    organization = "40demo"

    workspaces {
      name = "github-actions-infra-as-code-demo-azure"
    }
  }
}

provider "azurerm" {
  features {}
}



##############################################################################################################
# Accept the Terms license for the FortiGate Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
#resource "azurerm_marketplace_agreement" "fortinet" {
#  publisher = "fortinet"
#  offer     = "fortinet_fortigate-vm_v5"
#  plan      = var.FGT_IMAGE_SKU
#}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/26"  # External
    "2" = "172.16.136.64/26" # Internal
    "3" = "172.16.137.0/24"  # Protected a
    "4" = "172.16.138.0/24"  # Protected b
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # External
    "2" = "26" # Internal
    "3" = "24" # Protected a
    "4" = "24" # Protected b
  }
}

variable "fgt_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.5"  # External
    "2" = "172.16.136.69" # Internal
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1"  # External
    "2" = "172.16.136.65" # Internal
  }
}

variable "fgt_vmsize" {
  default = "Standard_F2s"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "GitHub Actions Infra As Code Demo Azure",
    environment : "staging"
  }
}

variable "backend_tags" {
  type = map(string)
  default = {
    template : "GitHub Actions Infra As Code Demo Azure",
    environment : "staging",
    type : "websrv",
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-RG"
  location = var.LOCATION
  tags     = var.fortinet_tags
}

##############################################################################################################
# Retrieve Flex VM token
##############################################################################################################
provider "fortiflexvm" {
  username       = var.FLEXVM_API_USERNAME
  password       = var.FLEXVM_API_PASSWORD
  import_options = ["program_serial_number=ELAVMR0000000287"]
}

data "fortiflexvm_configs_list" "example" {
  program_serial_number = "ELAVMR0000000287"
}

output "test" {
  value = data.fortiflexvm_configs_list.example
}

output "test2" {
  value = data.fortiflexvm_configs_list.example.configs[0]
}

/*
resource "fortiflexvm_config" "fortiflex-vm" {
  #terraform import fortiflexvm_config.fortiflex-vm 1
  product_type          = data.fortiflexvm_configs_list.example.configs[0].product_type
  program_serial_number = "ELAVMR0000000287"
}
*/


resource "fortiflexvm_entitlements_vm" "fortiflex-vm" {
  config_id   = data.fortiflexvm_configs_list.example.configs[0].id
  description = "Terraform auto deployed"
}

output "fortiflex-vm" {
  value = fortiflexvm_entitlements_vm.fortiflex-vm
}
output "fortiflex-vm_token" {
  value = fortiflexvm_entitlements_vm.fortiflex-vm.token
}

/*
variable "FLEXVM_API_USERNAME" {
  description = "FlexVM API username"
}

variable "FLEXVM_API_PASSWORD" {
  description = "FlexVM API password"
}

variable "FLEXVM_PROGRAM_SERIAL" {
  description = "FlexVM Program Serial"
}

variable "FLEXVM_CONFIG_NAME" {
  description = "FlexVM Config Name"
}

variable "FLEXVM_VM_SERIAL" {
  description = "FlexVM VM Serial"
}

data "external" "flexvm" {
  program = ["bash", "${path.root}/flexvm_ops.sh"]

  query = {
    apiUsername   = var.FLEXVM_API_USERNAME
    apiPassword   = var.FLEXVM_API_PASSWORD
    programSerial = var.FLEXVM_PROGRAM_SERIAL
    configName    = var.FLEXVM_CONFIG_NAME
    vmSerial      = var.FLEXVM_VM_SERIAL
    vmOp          = "TOKEN"
  }
}

output "flexvm_token" {
  value = data.external.flexvm.result.vmToken
}
*/
##############################################################################################################

