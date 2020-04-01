#!/usr/bin/env bash
#
#  - Environment build script for IoT Hub and IoT Edge deployments
#
# Usage:
#
#  AZ_SUBSCRIPTION_ID={Your-Azure-subscription-id} AZ_BASE_NAME={Unique-base-name} ./build_environment.sh
#
# Based on a template by BASH3 Boilerplate v2.3.0
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace


# Environment variables (and their defaults) that this script depends on
AZ_SUBSCRIPTION_ID="${AZ_SUBSCRIPTION_ID:-1234}"                        # Azure subscription id
AZ_REGION="${AZ_REGION:-eastus}"                                        # Azure region
AZ_BASE_NAME="${AZ_BASE_NAME:-GENUNIQUE}"                               # Base name for Azure resources


### Functions
##############################################################################

function __b3bp_log () {
  local log_level="${1}"
  shift

  # shellcheck disable=SC2034
  local color_info="\x1b[32m"
  local color_warning="\x1b[33m"
  # shellcheck disable=SC2034
  local color_error="\x1b[31m"

  local colorvar="color_${log_level}"

  local color="${!colorvar:-${color_error}}"
  local color_reset="\x1b[0m"

  if [[ "${NO_COLOR:-}" = "true" ]] || [[ "${TERM:-}" != "xterm"* ]] || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""; color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""

  while IFS=$'\n' read -r log_line; do
    echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2
  done <<< "${@:-}"
}

function error ()     { __b3bp_log error "${@}"; true; }
function warning ()   { __b3bp_log warning "${@}"; true; }
function info ()      { __b3bp_log info "${@}"; true; }


### Runtime
##############################################################################

if ! [ -x "$(command -v az)" ]; then
  error "command not found: az. Please install Azure CLI before executing this setup script. See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest to install Azure CLI."
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  error "command not found: jq. Please install jq before executing this setup script."
  exit 1
fi

if ! az iot -h > /dev/null ; then
  info "Az extension 'iot' is not installed. Intalling now"
  az extension add -y -n azure-cli-iot-ext
  info "Az extension 'iot' is installed now"
fi

# Initialize variables
rg_name="${AZ_BASE_NAME}-rg"
vm_name="${AZ_BASE_NAME}-vm-iotedge"
vm_image_urn="microsoft_iot_edge:iot_edge_vm_ubuntu:ubuntu_1604_edgeruntimeonly:latest"
vm_admin_username="azureuser"
hub_name="${AZ_BASE_NAME}-iothub"
hub_sku="S1"
device_id="edgeDevice"
acr_name="${AZ_BASE_NAME}acr"
acr_sku="Basic"

# info "Initiating login to Azure"
# az login > /dev/null
# info "Successfully login to Azure"

info "Setting Az CLI subscription context to '${AZ_SUBSCRIPTION_ID}'"
az account set \
--subscription "${AZ_SUBSCRIPTION_ID}"

info "Creating resource group '${rg_name}' in region '${AZ_REGION}'"
az group create \
--subscription "${AZ_SUBSCRIPTION_ID}" \
--location "${AZ_REGION}" \
--name "${rg_name}" 1> /dev/null

info "Accepting the terms of use for the Microsoft-provided Azure IoT Edge on Ubuntu virtual machine"
az vm image terms accept \
--urn "${vm_image_urn}"

info "Check whether virtual machine '${vm_name}' exist"
az vm show --resource-group "${rg_name}" \
--name "${vm_name}" 1> /dev/null

if [ $? -ne 0 ]; then
    info "Virtual machine '${vm_name}' does not exist. Creating a Microsoft-provided Azure IoT Edge on Ubuntu virtual machine '${vm_name}'"
    output=$(az vm create --resource-group "${rg_name}" \
    --name "${vm_name}" \
    --image "${vm_image_urn}" \
    --admin-username "${vm_admin_username}" \
    --generate-ssh-keys | jq ".")
    echo $output | jq
else
    info "Virtual machine '${vm_name}' exist. Proceeding.."
fi

info "Check whether IoT Hub '${hub_name}' exist"
az iot hub show --resource-group "${rg_name}" \
--name "${hub_name}" 1> /dev/null

if [ $? -ne 0 ]; then
    info "IoT Hub '${hub_name}' does not exist. Creating an IoT Hub '${hub_name}'"
    output=$(az iot hub create --resource-group "${rg_name}" \
    --name "${hub_name}" \
    --sku "${hub_sku}" | jq ".")
    echo $output | jq
else
    info "IoT Hub '${hub_name}' exist. Proceeding.."
fi

info "Check whether IoT edge device identity '${device_id}' exists in IoT Hub '${hub_name}'"
az iot hub device-identity show --hub-name "${hub_name}" \
--device-id "${device_id}" 1> /dev/null

if [ $? -ne 0 ]; then
    info "IoT edge device identity '${device_id}' does not exist in IoT Hub '${hub_name}'. Creating a device identity '${device_id}'"
    output=$(az iot hub device-identity create --hub-name "${hub_name}" \
    --device-id "${device_id}" \
    --edge-enabled | jq ".")
    echo $output | jq
else
    info "IoT edge device identity '${device_id}' exists in IoT Hub '${hub_name}'. Proceeding.."
fi

info "Retrieving connection string for IoT Edge device '${device_id}'"
device_connection_string=$(az iot hub device-identity show-connection-string \
--hub-name "${hub_name}" \
--device-id "${device_id}" | jq -r ".connectionString")

info "Configuring virtual machine '${vm_name}' to connect to IoT Hub"
az vm run-command invoke --resource-group "${rg_name}" \
--name "${vm_name}" \
--command-id RunShellScript \
--script "/etc/iotedge/configedge.sh '${device_connection_string}'"

info "Creating Azure container registry '${acr_name}'"
az acr create --resource-group "${rg_name}" \
--name "${acr_name}" \
--sku "${acr_sku}" \
--admin-enabled "true"
