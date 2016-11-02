# Why edge? https://github.com/aureliojargas/clitest/issues/17
FROM alpine:edge

MAINTAINER Aurelio Jargas <verde@aurelio.net>

# Perl is required by clitest's --regex matching mode
RUN apk --no-cache add perl

COPY clitest test.md /clitest/
COPY test/ /clitest/test/
RUN ln -s /clitest/clitest /usr/local/bin/clitest

CMD ["clitest", "--help"]
