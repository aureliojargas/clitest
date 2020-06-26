FROM alpine:3.11

# Perl is required by clitest's --regex matching mode
RUN apk --no-cache add \
    bash dash mksh zsh \
    perl \
    make \
    checkbashisms shellcheck

COPY clitest test.md /clitest/
COPY test/ /clitest/test/
RUN ln -s /clitest/clitest /usr/local/bin/clitest

WORKDIR /clitest
