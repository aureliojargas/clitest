# Developer workflow: run locally the same commands the CI will run.
# See the .github/workflows/check.yml file for the list of commands.
#
# By default, the linting and testing targets are run inside the
# clitest-dev Docker container. To run them directly on the host,
# avoiding the container, unset the `docker_run` variable. Examples:
#
#    make test-bash                # test using container's bash
#    make test-bash docker_run=    # test using host's bash

docker_image = clitest-dev
docker_tty = -t
docker_run = docker run --rm $(docker_tty) -v $$PWD:/mnt $(docker_image)
test_cmd = ./clitest --first --progress none test.md

default:
	@echo "Read the comments in the Makefile for help"

# Run-in-host targets

fmt-local:
	shfmt -w -i 4 -ci -kp -sr clitest

lint-local:
	shfmt -d -i 4 -ci -kp -sr clitest
	checkbashisms --posix clitest
	shellcheck clitest

test-local: test-bash-local test-dash-local test-mksh-local test-sh-local test-zsh-local
test-%-local:
	$* $(test_cmd)

# Run-in-Docker targets

fmt lint test test-bash test-dash test-mksh test-sh test-zsh:
	$(docker_run) make $@-local

# Docker-exclusive targets

docker-build:
	docker build -t $(docker_image) -f Dockerfile.dev .

docker-run:
	$(docker_run) $(cmd)

versions:
	@$(docker_run) sh -c 'apk list 2>/dev/null | cut -d " " -f 1 | sort'

