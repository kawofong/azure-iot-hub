# Azure IoT Hub [WIP]

This project demostrates the capabilities of Azure IoT Hub and how IoT devices and IoT edge integrate with IoT Hub.

## Prerequisite

- [Visual Studio Code](https://code.visualstudio.com/) configured with [Azure IoT Tools](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-tools)

- [Docker CE](https://docs.docker.com/install/)

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) with latest [IoT extension](https://github.com/Azure/azure-iot-cli-extension)

## Getting Started

- Fork this repo and clone your forked repo locally

- Run `AZ_SUBSCRIPTION_ID={Your-Azure-subscription-id} AZ_BASE_NAME={Unique-base-name} ./build_environment.sh` to build Azure environments
  - This will provision an [Azure IoT Hub](https://docs.microsoft.com/en-us/azure/iot-hub/), [Azure Linux VM with IoT Edge runtime](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge-ubuntuvm), and [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)

- Use VS code to open current directory
  - Replace line 16 of `deployment.template.json` and `deployment.debug.template.json` from `"address": "docker"` to `"address": "{your-container-registry-address}"`
  - Create new file `IoTEdgeSolution/.env`. Copy below content to env file

  ```bash
  CONTAINER_REGISTRY_USERNAME={your-container-registry-username}
  CONTAINER_REGISTRY_PASSWORD={your-container-registry-password}
  CONTAINER_REGISTRY_ADDRESS={your-container-registry-address}
  BUILD_BUILDID=1
  ```

  - To link Azure account and Azure IoT Hub to VS code, follow steps in the section "[Set up VS Code and tools](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-develop-for-linux#set-up-vs-code-and-tools)"
  - To build and push IoT modules, follow steps in the section "[Build and push your module](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-node-module#build-and-push-your-module)"
  - To deploy IoT modules to edge devices, follow steps in the section "[Deploy modules to device](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-node-module#deploy-modules-to-device)"
  - To edit module twin, follow steps in the section "[Edit the module twin](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-node-module#edit-the-module-twin)"

- Create new Azure DevOps service project
  - Create new "Azure Resource Manager" service connection named `AzureSubscriptionServiceConnection` and link it to your Azure subscription
  - Create new Azure Pipeline using your forked repo and YAML file `./azure-pipeline.yml`

## Next steps

- [] document steps to reproduce environment
- [] implement environment promotion

## Gotchas

- GitHub Action currently does not support Azure IoT Edge plugins

## References

- [Tutorial: Develop IoT Edge modules for Linux devices](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-develop-for-linux)
- [Tutorial: Develop and deploy a Node.js IoT Edge module for Linux devices](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-node-module)

---

### PLEASE NOTE FOR THE ENTIRETY OF THIS REPOSITORY AND ALL ASSETS

1. No warranties or guarantees are made or implied.
2. All assets here are provided by me "as is". Use at your own risk. Validate before use.
3. I am not representing my employer with these assets, and my employer assumes no liability whatsoever, and will not provide support, for any use of these assets.
4. Use of the assets in this repo in your Azure environment may or will incur Azure usage and charges. You are completely responsible for monitoring and managing your Azure usage.

---

Unless otherwise noted, all assets here are authored by me. Feel free to examine, learn from, comment, and re-use (subject to the above) as needed and without intellectual property restrictions.

If anything here helps you, attribution and/or a quick note is much appreciated.
