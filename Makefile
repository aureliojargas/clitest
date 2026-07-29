# Developer workflow: run locally the same commands the CI will run.
# See the .github/workflows/check.yml file for the list of commands.
#
# By default, the linting and testing targets are run inside the clitest-dev
# Docker container, because they require many different tools and shells to be
# installed. If you have these in your system, skip the container by unsetting
# the `docker_run` variable. Examples:
#
#    make test-bash                # test using container's Bash
#    make test-bash docker_run=    # test using host's Bash
#
# The clitest-dev Docker image will be built automatically on the first call to
# a container target (e.g., make lint) and then reused for the next calls. The
# image will be rebuilt when the `Dockerfile.dev` file changes or when the
# `.docker-build-done` file is removed.

docker_image = clitest-dev
docker_tty = -t
docker_run = docker run --rm $(docker_tty) -v $$PWD:/mnt $(docker_image)
test_cmd = clitest --first --progress none

# Set to `.docker-build-done` if $docker_run is non-empty, else leave empty
ensure_docker_build = $(if $(strip $(docker_run)),.docker-build-done)

default:
	@echo "Read the comments in the Makefile for help"

# Build if `Dockerfile.dev` file is newer than `.docker-build-done` file
.docker-build-done: Dockerfile.dev
	docker build -t $(docker_image) -f Dockerfile.dev .
	@touch $@

fmt: $(ensure_docker_build)
	$(docker_run) shfmt -w -i 4 -ci -kp -sr clitest

lint: $(ensure_docker_build)
	$(docker_run) shfmt -d -i 4 -ci -kp -sr clitest
	$(docker_run) checkbashisms --posix clitest
	$(docker_run) shellcheck clitest

# Aliases in pre-flight are necessary because there's calls to `clitest` from
# PATH in the documentation files.
validate-docs: $(ensure_docker_build)
	./$(test_cmd) --pre-flight 'alias clitest=./clitest' README.md
	./$(test_cmd) \
		examples/cut.txt \
		examples/hello-world.txt \
		examples/install-software.* \
		examples/intro.txt
	cd examples; ../$(test_cmd) --pre-flight 'alias clitest=../clitest' README.md

test: test-bash test-dash test-mksh test-sh test-zsh
test-%: $(ensure_docker_build)
	$(docker_run) $* ./$(test_cmd) test.md

versions: $(ensure_docker_build)
	@$(docker_run) sh -c 'apk list 2>/dev/null | cut -d " " -f 1 | sort'

docker-run: $(ensure_docker_build)
	$(docker_run) $(cmd)
