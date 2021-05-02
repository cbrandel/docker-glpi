# import config.
# You can change the default config with `make config="config_special.env" build`
config ?= config.env
include ${config}
export ${shell sed 's/=.*//' ${config}}

REGISTRY?=docker.io

.PHONY: all build

TAG 	:= ${shell git log -1 --pretty=%h}
IMG 	:= ${NAME}:${TAG}

all: build

build:
	@docker build --build-arg GLPI_VERSION=${GLPI_VERSION} -t ${IMG} .
	@docker tag ${IMG} ${REGISTRY}/${NAME}:${GLPI_VERSION}
	@docker tag ${IMG} ${REGISTRY}/${NAME}:latest

login:
	@docker login ${REGISTRY}

push: login
	@docker push --all-tags ${REGISTRY}/${NAME}