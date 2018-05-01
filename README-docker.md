# clitest Docker image

This is a [clitest](https://github.com/aureliojargas/clitest) Docker image based on the lightweight [Alpine Linux image](https://hub.docker.com/_/alpine/).

## Get it

```
docker pull aureliojargas/clitest
```

## Initial run

For the available clitest options, just run the image with no arguments:

```console
$ docker run --rm aureliojargas/clitest
Usage: clitest [options] <file ...>

Options:
  -1, --first                 Stop execution upon first failed test
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
  -t, --test RANGE            Run specific tests, by number (1,2,4-7)
  -s, --skip RANGE            Skip specific tests, by number (1,2,4-7)
      --pre-flight COMMAND    Execute command before running the first test
      --post-flight COMMAND   Execute command after running the last test
  -q, --quiet                 Quiet operation, no output shown
  -V, --version               Show program version and exit

Customization options:
  -P, --progress TYPE         Set progress indicator: test, number, dot, none
      --color WHEN            Set when to use colors: auto, always, never
      --diff-options OPTIONS  Set diff command options (default: '-u')
      --inline-prefix PREFIX  Set inline output prefix (default: '#=> ')
      --prefix PREFIX         Set command line prefix (default: '')
      --prompt STRING         Set prompt string (default: '$ ')
$
```

## Test your own files

To run clitest on your own test files, map their directory with `-v`. For example, mapping the current directory to container's `/src` and testing the `test.md` file:

```
docker run --rm -v "$PWD:/src/" aureliojargas/clitest /src/test.md
```

Same as before, but this time using `-w` to set the current directory to `/src`, making sure the execution happens inside your directory:

```
docker run --rm -v "$PWD:/src/" -w /src aureliojargas/clitest test.md
```

If you don't have any test files right now, you can see clitest in action by running its own test suite:

```console
$ docker run --rm -w /clitest aureliojargas/clitest test.md
#1    test -f ./clitest; echo $?
#2    test -d ./test/; echo $?
#3    COLUMNS=80
#4    export COLUMNS
#5    echo $COLUMNS
...
#260  ./clitest test/blank-output.sh
#261  ./clitest test/no-nl-file-1.sh
#262  ./clitest test/no-nl-file-2.sh
#263  ./clitest test/no-nl-file-3.sh
#264  ./clitest test/no-nl-command.sh
#265  ./clitest --color yes --first test/fail-2.sh
OK: 265 of 265 tests passed
$
```

## Build

To build this image, go to clitest repository root and run:

```
docker build -t aureliojargas/clitest .
```


## About clitest

[Clitest](https://github.com/aureliojargas/clitest) is a portable POSIX shell script that performs automatic testing in Unix command lines.

It's the same concept as in [Python's doctest module](http://en.wikipedia.org/wiki/Doctest). You save the commands and their expected output in a text file:

```
$ echo "Hello World"
Hello World
$ cd /tmp
$ pwd
/tmp
$ cd "$OLDPWD"
$
```

and then use clitest to run those commands and compare their output:

```console
$ clitest examples/intro.txt
#1      echo "Hello World"
#2      cd /tmp
#3      pwd
#4      cd "$OLDPWD"
OK: 4 of 4 tests passed
$
```

That's it!

- **There's no syntax to learn**, just copy/paste the command line history into a text file.
- Useful for automated testing and testable documentation (Markdown file with commands).

See examples and instructions in the [GitHub repository](https://github.com/aureliojargas/clitest).
