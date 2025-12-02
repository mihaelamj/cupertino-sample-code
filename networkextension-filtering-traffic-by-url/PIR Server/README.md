# PIR Server

The included Dockerfile will build a [Docker](https://www.docker.com) container which can be used to run a sample PIR server service.

## Overview

A [Private Information Retrieval](https://en.wikipedia.org/wiki/Private_information_retrieval) (PIR) server provides a means to query the server while maintaining user privacy. 

A sample, non-scalable, [PIRService](https://github.com/apple/live-caller-id-lookup-example/tree/main/Sources/PIRService) is available as part of the [Live Caller ID Lookup Example](https://github.com/apple/live-caller-id-lookup-example), so we can use this implementation, with a configuration appropriate for URL filtering, to build and run the service.

The `Dockerfile` details the specific steps to build and configure the service appropriately. The build steps are derived from the [Testing Live Caller ID Lookup](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice/testinginstructions) instructions, with changes for this use case; namely, we can skip the `PIRProcessDatabase` step in the instructions. While the `Dockerfile` is available it is not required, and you are welcome to perform the steps manually.
 
The resulting container can be used to run the PIRService server, configured to work in tandem with the SimpleURLFilter sample application.

## Configure the sample code project

The configuration is already in place, and no changes are needed. However, some important details to consider should you want to alter the configuration:

1. The `service-config.json` contains a usecase in the `usecases` array whose `name` must match the Bundle ID of the application which will configure URL filtering, with the addition of a `.url.filtering` suffix.

	i.e. `com.example.apple-samplecode.SimpleURLFilter.url.filtering`

1. The `data` directory contains the `url-config.json` which identifies the database contents and configures related parameters.

1. The `data` directory contains the `input.txtpb` file which is the content of the database, configured with sample URLs which are to be blocked.

## Build and Run

**NOTE:** [Docker](https://www.docker.com), or compatible alternative, will need to be installed to build and run the container.

The `Dockerfile` and related `compose.yml` are configured to build the server and start it running on port 8080.

To build and run, open a Terminal window in the folder which contains the `compose.yml` and `Dockerfile` and use the `docker compose up` command:

	% docker compose up

This will download the needed resources, build, and start the server running on port 8080.

## See Also

* [Testing Live Caller ID Lookup](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice/testinginstructions)
