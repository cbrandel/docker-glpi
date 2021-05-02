DOCKER_REPO = cbrandel

.PHONY: all build

TAG_NAME := $(shell git tag -l --contains HEAD)
GIT_BRANCH := $(subst heads/,,$(shell git rev-parse --abbrev-ref HEAD 2>/dev/null))
GLPI_DEV_IMAGE := glpi-dev$(if $(TAG_NAME),:$(subst /,-,$(TAG_NAME)))
GLPI_IMAGE := "cbrandel/glpi"

all: build

build: build-glpi-dev

build-glpi-dev:
	docker build ${DOCKER_FLAGS} -t ${GLPI_DEV_IMAGE} .

build-glpi:
	docker build ${DOCKER_FLAGS} -t ${GLPI_IMAGE}:${TAG_NAME} .
