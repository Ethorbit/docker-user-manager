build: ../build/Dockerfile ../build/start.sh 
	docker-compose -f ./setup_users/docker-compose.yml build
	touch $@

.PHONY: test
test: build
	HUID=$(shell id -u) HGID=$(shell id -g) docker-compose -f ./setup_users/docker-compose.yml up
	set -a && source ./data/users/env &&\
		docker-compose -f ./your_project/docker-compose.yml up

