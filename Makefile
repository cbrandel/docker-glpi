DOCKER_REPO = cbrandel

.PHONY: all build

all: build

build: build-glpi

build-glpi:
	docker build ${DOCKER_FLAGS} -t ${DOCKER_REPO}:glpi .
