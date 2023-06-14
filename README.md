# clitest – Command Line Tester

clitest is a [portable][1] POSIX shell script that performs automatic
testing in Unix command lines.

It's the same concept as in Python's [doctest][2] module: you document
both the commands and their expected output, using the familiar
interactive prompt format, and a specialized tool tests them.

In fact, the doctest [official][3] description can also be used for
clitest:

* The **doctest** module searches for pieces of text that look like
  interactive **Python sessions**, and then executes those **sessions**
  to verify that they work exactly as shown.

* The **clitest** command searches for pieces of text that look like
  interactive **Unix command lines**, and then executes those
  **command lines** to verify that they work exactly as shown.


## Download & install

The full program is just [a single shell script file][4].

Save it, make it executable and move it to a `$PATH` directory:

```bash
curl -sOL https://raw.githubusercontent.com/aureliojargas/clitest/master/clitest
chmod +x clitest
sudo mv clitest /usr/bin
```

Now check if everything is fine:

```
clitest --help
```


## Docker image

You can also run clitest in a Docker container ([more info in Docker Hub](https://hub.docker.com/r/aureliojargas/clitest)).

```
docker run --rm -t aureliojargas/clitest --help
```


## Quick Intro

Save the commands and their expected output in a text file:

♦ [examples/intro.txt][5]

```
$ echo "Hello World"
Hello World
$ cd /tmp
$ pwd
/tmp
$ cd "$OLDPWD"
$
```

Use clitest to run these commands and check their output:

```console
$ clitest examples/intro.txt
#1	echo "Hello World"
#2	cd /tmp
#3	pwd
#4	cd "$OLDPWD"
OK: 4 of 4 tests passed
$
```


## CLI Syntax

There's no syntax to learn.

The test files are identical to the good old command line interface
(CLI) you're so familiar:

♦ [examples/cut.txt][6]

```
$ echo "one:two:three:four:five:six" | cut -d : -f 1
one
$ echo "one:two:three:four:five:six" | cut -d : -f 4
four
$ echo "one:two:three:four:five:six" | cut -d : -f 1,4
one:four
$ echo "one:two:three:four:five:six" | cut -d : -f 4,1
one:four
$ echo "one:two:three:four:five:six" | cut -d : -f 1-4
one:two:three:four
$ echo "one:two:three:four:five:six" | cut -d : -f 4-
four:five:six
$
```

That's it.

Just paste your shell session inside a text file and you have a
ready-to-use test suite.

```console
$ clitest examples/cut.txt
#1	echo "one:two:three:four:five:six" | cut -d : -f 1
#2	echo "one:two:three:four:five:six" | cut -d : -f 4
#3	echo "one:two:three:four:five:six" | cut -d : -f 1,4
#4	echo "one:two:three:four:five:six" | cut -d : -f 4,1
#5	echo "one:two:three:four:five:six" | cut -d : -f 1-4
#6	echo "one:two:three:four:five:six" | cut -d : -f 4-
OK: 6 of 6 tests passed
$
```

There are more examples and instructions in the [examples folder][10].
For a real-life collection of hundreds of test files, see
[funcoeszz test files][24].


## Testable Documentation

Clitest can also **extract and run command lines from documentation**,
such as Markdown files. This very `README.md` file you are now reading
is testable with `clitest README.md`. All the command lines inside it
will be run and checked.

No more malfunctioning shell commands in your READMEs, you can have
testable documentation.

Given the following Markdown sample document:

♦ [examples/cut.md][7]

```
The numeric ranges of the Unix command "cut"
============================================

Use single numbers to extract one specific field:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1
	one
	$ echo "one:two:three:four:five:six" | cut -d : -f 4
	four

Use commas to inform more than one field:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1,4
	one:four

Note that inverting the order will *not* invert the output:

	$ echo "one:two:three:four:five:six" | cut -d : -f 4,1
	one:four

Use an hyphen to inform a range of fields, from one to four:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1-4
	one:two:three:four

If you omit the second range number, it matches until the last:

	$ echo "one:two:three:four:five:six" | cut -d : -f 4-
	four:five:six

cut is cool, isn't it?
```

It is a technical article, not a boring code-only test file. You can
read its final (formatted) version [here][7].

You can give this article to clitest, who will identify all the shell
command lines inside it, run them and check if the results are the
same.

```console
$ clitest --prefix tab examples/cut.md
#1	echo "one:two:three:four:five:six" | cut -d : -f 1
#2	echo "one:two:three:four:five:six" | cut -d : -f 4
#3	echo "one:two:three:four:five:six" | cut -d : -f 1,4
#4	echo "one:two:three:four:five:six" | cut -d : -f 4,1
#5	echo "one:two:three:four:five:six" | cut -d : -f 1-4
#6	echo "one:two:three:four:five:six" | cut -d : -f 4-
OK: 6 of 6 tests passed
$
```

Note the use of `--prefix tab` option, to inform clitest that the code
blocks are prefixed by a tab in this Markdown file. For files with
4-spaces indented code blocks, use `--prefix 4`. When using
non-indented fenced code blocks (\`\`\`), such as this [README.md][8],
no prefix option is needed.

Examples of testable documentation handled by clitest:

* https://github.com/aureliojargas/txt2regex/blob/master/tests/features.md
* https://github.com/aureliojargas/txt2regex/blob/master/tests/cmdline.md
* https://github.com/aureliojargas/sedsed/blob/master/test/command_line.md
* https://github.com/aureliojargas/replace/blob/master/README.md
* https://github.com/aureliojargas/clitest/blob/master/test.md
* https://github.com/caarlos0/jvm/blob/master/tests/test.clitest.md
* https://github.com/caarlos0/git-add-remote/blob/master/tests/suite.clitest.md


## Alternative Syntax: Inline Output

Now a nice extension to the original idea. Using the special marker
`#=>` you can embed the expected command output at the end of the
command line.

```console
$ echo "foo"                      #=> foo
$ echo $((10 + 2))                #=> 12
```

This is the same as doing:

```console
$ echo "foo"
foo
$ echo $((10 + 2))
12
$
```

Inline outputs are very readable when testing series of commands that
result in short texts.

```console
$ echo "abcdef" | cut -c 1        #=> a
$ echo "abcdef" | cut -c 4        #=> d
$ echo "abcdef" | cut -c 1,4      #=> ad
$ echo "abcdef" | cut -c 1-4      #=> abcd
```

> Note: If needed, you can change this marker (i.e., to `#→` or `###`)
> at the top of the script or using the `--inline-prefix` option.


## Advanced Tests

When using the `#=>` marker, you can take advantage of special options
to change the default output matching method.

```console
$ head /etc/passwd            #=> --lines 10
$ tac /etc/passwd | tac       #=> --file /etc/passwd
$ cat /etc/passwd             #=> --egrep ^root:
$ echo $((2 + 10))            #=> --regex ^\d+$
$ make test                   #=> --exit 0
$ pwd                         #=> --eval echo $PWD
```

* Using `#=> --lines` the test will pass if the command output has
  exactly `N` lines. Handy when the output text is variable
  (unpredictable), but the number of resulting lines is constant.

* Using `#=> --file` the test will pass if the command output matches
  the contents of an external file. Useful to organize long/complex
  outputs into files.

* Using `#=> --egrep` the test will pass if `grep -E` matches at least
  one line of the command output.

* Using `#=> --regex` the test will pass if the command output is
  matched by a [Perl regular expression][9]. A multiline output is
  matched as a single string, with inner `\n`'s. Use the `(?ims)`
  modifiers when needed.

* Using `#=> --exit` the test will pass if the exit code of the command
  is equal to the code specified. Useful when testing commands that
  generate variable output (or no output at all), and the exit code is
  the best indication of success. Both STDIN and STDOUT are ignored
  when using this option.

* Using `#=> --eval` the test will pass if both commands result in the
  same output. Useful to expand variables which store the full or
  partial output.

## Options

```console
$ clitest --help
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


## Exit codes

* `0` - All tests passed, or normal operation (--help, --list, …)
* `1` - One or more tests have failed
* `2` - An error occurred (file not found, invalid range, …)


## Fail fast

Use the `--first` option (or the short version `-1`) to abort the
execution when any test fails.

Useful for Continuous Integration (CI), or when running sequential
tests where the next test depends on the correct result of the
previous.


## Quiet operation

When automating the tests execution, use `--quiet` to show no output and
just check the exit code to make sure all tests have passed. Using
`--first` to fail fast is also a good idea in this case.

```bash
if clitest --quiet --first tests.txt
then
    # all tests passed
else
    # one or more tests failed :(
fi
```


## Run specific tests

To rerun a specific problematic test, or to limit the execution to a
set of tests, use `--test`. To ignore one or more tests, use `--skip`.
If needed, you can combine both options to inform a very specific test
range. Examples:

```bash
clitest --test 1-10    tests.txt   # Run the first 10 tests
clitest --test 1,2,6-8 tests.txt   # Run tests #1, #2, #6, #7 and #8
clitest --skip 11,15   tests.txt   # Run all tests, except #11 and #15
clitest -t 1-10 -s 5   tests.txt   # Run first 10 tests, but skip #5
```


## Pre/post scripts

You can run a preparing script or command before the first test with
`--pre-flight`, for setting env variables and create auxiliary files.
At the end of all tests, run a final cleanup script/command with
`--post-flight` to remove temporary files or other transient data.

```bash
clitest --pre-flight ./test-init.sh --post-flight 'rm *.tmp' tests.txt
```


## Customization

Use the customization options to extract and test command lines from
documents or wiki pages. For example, to test all the command line
examples listed inside a Markdown file using the 4-spaces syntax for
code blocks:

```bash
clitest --prefix 4 README.md
```

Or maybe you use a different prompt (`$PS1`) in your documentation?

```bash
clitest  --prefix 4 --prompt '[john@localhost ~]$ ' README.md
```




## Nerdiness

* Use any text file format for the tests, it doesn't matter. The command
  lines just need to be grepable and have a fixed prefix (or even none).
  Even Windows text files (CR+LF) will work fine.

* The command line power is available in your test files: use variables,
  pipes, redirection, create files, folders, move around…

* All the commands are tested using a single shell session. This means
  that variables, aliases and functions defined in one test will persist
  in the following tests.

* Both STDOUT and STDERR are captured, so you can also test error
  messages.

* To test STDOUT/STDERR and the exit code at the same time, add a
  `;echo $?` after the command.

* Use an empty `$` prompt to close the last command output.

* In the output, every single char (blank or not) counts. Any
  difference will cause a test to fail. To ignore the difference in
  blanks, use `--diff-options '-u -w'`.

* Unlike doctest's `<BLANKLINE>`, in clitest blank lines in the
  command output aren't a problem. Just insert them normally.

* To test outputs with no final `\n`, such as `printf foo`, use `#=>
  --regex ^foo$`.

* In multifile mode, the current folder (`$PWD`) is reset when
  starting to test a new file. This avoids that a `cd` command in a
  previous file will affect the next.

* Multiline prompts (`$PS2`) are not yet supported.

* Ellipsis (as in doctest) are not supported. Use `#=> --regex`
  instead.

* Simple examples in [examples/][10]. Hardcore examples in
  [test.md][11] and [test/][12], the clitest own test-suite.


## Choose the execution shell

The clitest shebang is `#!/bin/sh`. That's the default shell that will
be used to run your test command lines. Depending on the system, that
path points to a different shell, such as ash, dash, or bash
([running in POSIX mode][23]).

To force your test commands to always run on a specific shell, just call
the desired shell before:

```bash
clitest tests.txt            # Uses /bin/sh
bash clitest tests.txt       # Uses Bash
ksh clitest tests.txt        # Uses Korn Shell
```

## Portability

This script was carefully coded to be portable between [POSIX][13]
shells. It's code is validated by [checkbashisms][25] and
[shellcheck][26].

To make sure it keeps working as expected, after every change clitest is
automatically tested in the CI, using the following shells:

- bash
- dash
- ksh
- sh (busybox)
- zsh

> Fish shell is not supported (it's not POSIX), but you 
> can use [doctest.fish][27] instead.

Portability issues are considered serious bugs, please
[report them][14]!

Developers: Learn more about portability in POSIX shells:

* [How to make bash scripts work in dash][15]
* [Ubuntu — Dash as /bin/sh][16]
* [Rich’s sh (POSIX shell) tricks][17]
* [lintsh][18]
* [Official POSIX specification: Shell & Utilities][19]


## [KISS][20]

A shell script to test shell commands.  
No other language or environment involved.


## Meta

* Author:   [Aurelio Jargas][21]
* Created:  2013-07-24
* Language: Shell Script
* License:  [MIT][22]


[1]: #portability
[2]: http://en.wikipedia.org/wiki/Doctest
[3]: http://docs.python.org/3/library/doctest.html
[4]: https://raw.github.com/aureliojargas/clitest/master/clitest
[5]: https://github.com/aureliojargas/clitest/blob/master/examples/intro.txt
[6]: https://github.com/aureliojargas/clitest/blob/master/examples/cut.txt
[7]: https://github.com/aureliojargas/clitest/blob/master/examples/cut.md
[8]: https://github.com/aureliojargas/clitest/blob/master/README.md
[9]: http://perldoc.perl.org/perlre.html
[10]: https://github.com/aureliojargas/clitest/tree/master/examples
[11]: https://github.com/aureliojargas/clitest/blob/master/test.md
[12]: https://github.com/aureliojargas/clitest/blob/master/test/
[13]: http://en.wikipedia.org/wiki/POSIX
[14]: https://github.com/aureliojargas/clitest/issues
[15]: http://mywiki.wooledge.org/Bashism
[16]: https://wiki.ubuntu.com/DashAsBinSh
[17]: http://www.etalabs.net/sh_tricks.html
[18]: http://code.dogmap.org/lintsh/
[19]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
[20]: http://en.wikipedia.org/wiki/KISS_principle
[21]: http://aurelio.net/about.html
[22]: https://github.com/aureliojargas/clitest/blob/master/LICENSE.txt
[23]: https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html
[24]: https://github.com/funcoeszz/funcoeszz/tree/master/testador
[25]: https://linux.die.net/man/1/checkbashisms
[26]: https://www.shellcheck.net/
[27]: https://github.com/aureliojargas/doctest.fish
