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
docker_run = docker run --rm -t -v $$PWD:/mnt $(docker_image)
test_cmd = ./clitest --first --progress none test.md

default:
	@echo "Read the comments in the Makefile for help"

fmt:
	$(docker_run) shfmt -w -i 4 -ci -kp -sr clitest

lint:
	$(docker_run) shfmt -d -i 4 -ci -kp -sr clitest
	$(docker_run) checkbashisms --posix clitest
	$(docker_run) shellcheck clitest

test: test-bash test-dash test-mksh test-sh test-zsh
test-%:
	$(docker_run) $* $(test_cmd)

versions:
	@$(docker_run) sh -c 'apk list 2>/dev/null | cut -d " " -f 1 | sort'

docker-build:
	docker build -t $(docker_image) -f Dockerfile.dev .

docker-run:
	$(docker_run) $(cmd)
