INVENTORY := "whatever.yaml"
PLAYBOOK := "whatever.yaml"
CONTAINERS := $(shell \
	if [ -f "ansible/$(INVENTORY)" ]; then \
		yq -r '.all.hosts | keys | .[]' \
			< "ansible/$(INVENTORY)" ;\
	fi \
)
VERBOSITY := "-v"

default: help

help:
	@grep -B1 -E "^[a-zA-Z0-9_-]+\:([^\=]|$$)" Makefile \
		| grep -v -- -- \
		| sed 'N;s/\n/###/' \
		| sed -n 's/^#: \(.*\)###\([^:]*\):.*/\2###\1/p' \
		| column -t -s '###'

#: Tests all ansible playbooks
test: lint
	# Make sure the id_rsa is not publicly accessible
	# Happens in some git checkouts
	chmod go-rwx docker/ssh/id_rsa && \
	$(MAKE) \
		debug INVENTORY="inventory/docker-test.yaml" \
		launch INVENTORY="inventory/docker-test.yaml" \
		deploy VERBOSITY="-vv" PLAYBOOK="docker-test.yaml" INVENTORY="inventory/docker-test.yaml" \
		shutdown INVENTORY="inventory/docker-test.yaml" \
	|| $(MAKE) shutdown INVENTORY="inventory/docker-test.yaml"

debug:
	@echo $(INVENTORY) ":" $(CONTAINERS)

#: Yaml lint the ansible directory
lint:
	yamllint ansible/

#: Deploys the raspberry-pi playbook; also used by test for the test playbook
deploy:
	cd ansible && \
	ansible-playbook \
		--private-key ../docker/ssh/id_rsa \
		--inventory "$(INVENTORY)" \
		"$(PLAYBOOK)" \
		"$(VERBOSITY)"

#: Builds the test docker image
build:
	cd docker && \
	docker build --tag raspbian-test .

#: Launches the test docker containers defined in the docker-test inventory
launch: build $(CONTAINERS:=-launch)

$(CONTAINERS:=-launch):
	docker run \
		--interactive \
		--tty \
		--privileged \
		--hostname $(@:-launch=) \
		--name $(@:-launch=) \
		--detach \
		--publish $(shell \
			yq -r '.all.hosts["'$(@:-launch=)'"].ansible_ssh_port' \
			< "ansible/$(INVENTORY)" \
			):22 \
		raspbian-test

#: Shuts doen the test docker containers defined in the docker-test inventory
shutdown: $(CONTAINERS:=-shutdown)

$(CONTAINERS:=-shutdown):
	docker rm --force $(@:-shutdown=)
