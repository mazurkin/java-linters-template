# Makefile
#
# https://swcarpentry.github.io/make-novice/reference.html
# https://www.cs.colby.edu/maxwell/courses/tutorials/maketutor/
# https://www.gnu.org/software/make/manual/make.html
# https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html

SHELL := /bin/bash

DOCKER_NAME := "local/java-linters-template"

export JAVA_HOME=${JAVA21_HOME}

# -----------------------------------------------------------------------------
# welcome
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = info

.PHONY: info
info:
	@echo "JDK:${JAVA_HOME}"

# -----------------------------------------------------------------------------
# maven
# -----------------------------------------------------------------------------

.PHONY: build
build:
	@mvn --batch-mode clean package

.PHONY: release
release:
	@mvn --batch-mode release:prepare -P docker
	@mvn --batch-mode release:perform -P docker

.PHONY: shellcheck
shellcheck:
	@mvn --batch-mode exec:exec -N -P shellcheck

.PHONY: owasp-dependency
owasp-dependency:
	@mvn --batch-mode dependency-check:aggregate -P owasp-dependency

# -----------------------------------------------------------------------------
# docker
# -----------------------------------------------------------------------------

.PHONY: docker-build
docker-build: docker-prune
	@mvn --batch-mode clean package -P docker

.PHONY: docker-deploy
docker-deploy: docker-prune
	@mvn --batch-mode clean deploy -P docker

.PHONY: docker-push
docker-push:
	$(eval DOCKER_VERSION := $(shell mvn -f pom.xml help:evaluate -Dexpression=project.version --quiet -DforceStdout))
	$(eval DOCKER_IMAGE   := "$(DOCKER_NAME):$(DOCKER_VERSION)")
	@docker push "$(DOCKER_IMAGE)"

.PHONY: docker-run
docker-run: info
	$(eval DOCKER_VERSION := $(shell mvn -f pom.xml help:evaluate -Dexpression=project.version --quiet -DforceStdout))
	$(eval DOCKER_IMAGE   := "$(DOCKER_NAME):$(DOCKER_VERSION)")
	$(eval DEBUG_PORT     := 12321)
	$(eval JAVA_OPTIONS   := "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=0.0.0.0:$(DEBUG_PORT)")
	@docker run \
		--rm \
		--name "linters" \
		--hostname="linters" \
		--interactive \
		--tty \
		--read-only \
		--publish "0.0.0.0:$(DEBUG_PORT):$(DEBUG_PORT)/tcp" \
		--env "JAVA_OPTIONS=$(JAVA_OPTIONS)" \
		"$(DOCKER_IMAGE)"

.PHONY: docker-shell
docker-shell: info
	$(eval DOCKER_VERSION := $(shell mvn -f pom.xml help:evaluate -Dexpression=project.version --quiet -DforceStdout))
	$(eval DOCKER_IMAGE   := "$(DOCKER_NAME):$(DOCKER_VERSION)")
	@docker run \
		--rm \
		--name "linters" \
		--hostname="linters" \
		--interactive \
		--tty \
		--read-only \
		--entrypoint "/bin/bash" \
		"$(DOCKER_IMAGE)"

.PHONY: docker-prune
docker-prune:
	@docker image prune --force

# -----------------------------------------------------------------------------
# version
# -----------------------------------------------------------------------------

.PHONY: version-next-minor
version-next-minor:
	@mvn build-helper:parse-version versions:set -DnewVersion=\$${parsedVersion.majorVersion}.\$${parsedVersion.nextMinorVersion}.0-SNAPSHOT versions:commit

.PHONY: version-next-major
version-next-major:
	@mvn build-helper:parse-version versions:set -DnewVersion=\$${parsedVersion.nextMajorVersion}.0.0-SNAPSHOT versions:commit
