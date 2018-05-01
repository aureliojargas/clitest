FROM alpine:3.7

MAINTAINER Aurelio Jargas <verde@aurelio.net>

# Perl is required by clitest's --regex matching mode
RUN apk --no-cache add perl

COPY clitest test.md /clitest/
COPY test/ /clitest/test/
RUN ln -s /clitest/clitest /usr/local/bin/clitest

ENTRYPOINT ["clitest"]
CMD ["--help"]
