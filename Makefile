# Developer workflow: run locally the same commands Travis will run in
# the CI. See the .travis.yml file for the list of commands.
#
# By default, the linting and testing targets are run inside the clitest
# Docker container. To run them directly on the host, avoiding the
# container, unset the `docker_run` variable. Examples:
#
#    make test-bash                # test using container's bash
#    make test-bash docker_run=    # test using host's bash

docker_image = aureliojargas/clitest
docker_run = docker run --rm -it -v $$PWD:/clitest $(docker_image)
test_cmd = clitest --first --progress none test.md

default:
	@echo "Read the comments in the Makefile for help"

lint:
	$(docker_run) checkbashisms --posix clitest

test: test-bash test-dash test-mksh test-sh test-zsh
test-%:
	$(docker_run) $* $(test_cmd)

versions:
	@$(docker_run) sh -c 'apk list 2>/dev/null | cut -d " " -f 1 | sort'

docker-build:
	docker build -t $(docker_image) .

docker-run:
	$(docker_run) $(cmd)
