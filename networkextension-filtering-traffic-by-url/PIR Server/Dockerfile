##
# A sample PIR Server
#
# See:
# https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice/testinginstructions
# https://docs.docker.com/reference/dockerfile/
#
### Building
#
# Ideally, just use:
#
#	% docker compose up
#
# which will use the `compose.yml` file, and configuration within, to build and run the
# server. You can rebuild with `docker compose build`
#
# Non-Compose Build:
#
# NOTE: The default memory allocation appears to be too small to allow th
# `swift package experimental-install` commands to succeed.
# To address this we add the `--shm-size 2g` option to the build command.
#
#	From the same directory as the `Dockerfile` execute the following build command, which
#   will build the container and name it `pir-server`:
#	
#		% docker buildx build --shm-size 2g -t pir-server .
#
### Running from the container
#	
#	Once built, the container can be run:
#	
#		% docker run pir-server
#	
###

FROM swift:6.1 AS builder

WORKDIR /pir

# Install and build tools

RUN git clone https://github.com/apple/live-caller-id-lookup-example.git
RUN git clone https://github.com/apple/swift-homomorphic-encryption

RUN cd swift-homomorphic-encryption; \
	git checkout 1.0.3; \
	swift package experimental-install -c release --product PIRProcessDatabase

RUN cd live-caller-id-lookup-example; \
	swift package experimental-install -c release --product PIRService

# Construct Database

RUN mkdir data

COPY data/ data/

RUN cd data; \
	~/.swiftpm/bin/PIRProcessDatabase url-config.json

####

FROM swift:6.1-slim

WORKDIR /pir

COPY service-config.json .
COPY --from=builder /root/.swiftpm/bin/PIRService ./bin/PIRService

COPY --from=builder [ \
	"/pir/data/url-*.bin", \
	"/pir/data/url-*.params.txtpb", \
	"./" ]

# /pir/bin/PIRService --hostname 0.0.0.0 --port 8080 service-config.json
CMD ["--hostname", "0.0.0.0", "--port", "8080", "service-config.json"]
ENTRYPOINT ["/pir/bin/PIRService"]
