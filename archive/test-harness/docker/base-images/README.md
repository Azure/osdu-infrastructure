# Cobalt Test Base Image

This is the base image used for running terratest based unit and integration GO tests. This image comes pre-packaged with the following dependencies:
* Go programming language: Terraform test cases are written in [Go](https://golang.org/dl/).
* dep: [dep](https://github.com/golang/dep#installation) is a dependency management tool for Go.
* Azure CLI: The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) is a command-line tool you can use to manage Azure resources. (Terraform supports authenticating to Azure through a service principal or via the Azure CLI.)
* mage: We use the mage go [module](https://github.com/magefile/mage#installation) to show you how to simplify running Terratest cases.

## Getting Started

You can build this image locally using a different golang version following the example below.

### Prerequisities

In order to run this container you'll need docker installed.

* [Windows](https://docs.docker.com/windows/started)
* [OS X](https://docs.docker.com/mac/started/)
* [Linux](https://docs.docker.com/linux/started/)

### Usage

#### Image Build Parameters

**govver**

Golang version specification. This argument drives the version of the `golang` stretch base image.

**tfver**

Terraform version specification. This argument drives which terraform version release this image will use.

```shell
docker build -f "test-harness\docker\base-images\Dockerfile" -t msftcse/cobalt-test-base:1.12.5 . --build-arg gover=1.12.5 tfver=0.12.2
```
## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* [@erikschlegel](https://github.com/erikschlegel)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.


## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.