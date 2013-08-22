# cltest – Command Line Tester

cltest is a [portable](#portability) POSIX shell script that performs automatic testing in Unix command lines.

It's the same concept as in Python's [doctest](http://en.wikipedia.org/wiki/Doctest) module: you document both the commands and their expected output, **using the familiar interactive prompt format**, and a specialized tool tests them.

In fact, the doctest [official](http://docs.python.org/3/library/doctest.html) description can also be used for cltest:

* The **doctest** module searches for pieces of text that look like interactive **Python sessions**, and then executes those **sessions** to verify that they work exactly as shown.

* The **cltest** command searches for pieces of text that look like interactive **Unix command lines**, and then executes those **command lines** to verify that they work exactly as shown.


## Download

The full program is just [a single shell script file](https://raw.github.com/aureliojargas/cltest/master/cltest).
Save it and make it executable: `chmod +x cltest`


## Quick Intro

Save the commands and their expected output in a text file:

♦ [examples/intro.txt](https://github.com/aureliojargas/cltest/blob/master/examples/intro.txt)

```
$ echo "Hello World"
Hello World
$ cd /tmp
$ pwd
/tmp
$ cd "$OLDPWD"
$
```

Use cltest to run these commands and check their output:

```
$ cltest examples/intro.txt
#1	echo "Hello World"
#2	cd /tmp
#3	pwd
#4	cd "$OLDPWD"
OK: 4 of 4 tests passed
$
```


## CLI Syntax

There's no syntax to learn.

The test files are identical to the good old command line interface (CLI) you're so familiar:

♦ [examples/cut.txt](https://github.com/aureliojargas/cltest/blob/master/examples/cut.txt)

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

Just paste your shell session inside a text file and you have a ready-to-use test suite.

```
$ cltest examples/cut.txt
#1	echo "one:two:three:four:five:six" | cut -d : -f 1
#2	echo "one:two:three:four:five:six" | cut -d : -f 4
#3	echo "one:two:three:four:five:six" | cut -d : -f 1,4
#4	echo "one:two:three:four:five:six" | cut -d : -f 4,1
#5	echo "one:two:three:four:five:six" | cut -d : -f 1-4
#6	echo "one:two:three:four:five:six" | cut -d : -f 4-
OK: 6 of 6 tests passed
$
```


## Test Documents

Ever wanted to test the command line instructions you give in the `INSTALL.txt` or `README.md` files for your projects? Now you can!

cltest can also extract and run command lines from technical documents.

Given the following Markdown sample document, which uses tabs to mark code blocks:

♦ [examples/cut.md](https://github.com/aureliojargas/cltest/blob/master/examples/cut.md)

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

It's easy to convert it to a readable HTML document with your favorite Markdown program. It's also easy to test this file directly with cltest, just inform that the command lines are prefixed by a tab:

```
$ cltest --prefix tab examples/cut.md
#1	echo "one:two:three:four:five:six" | cut -d : -f 1
#2	echo "one:two:three:four:five:six" | cut -d : -f 4
#3	echo "one:two:three:four:five:six" | cut -d : -f 1,4
#4	echo "one:two:three:four:five:six" | cut -d : -f 4,1
#5	echo "one:two:three:four:five:six" | cut -d : -f 1-4
#6	echo "one:two:three:four:five:six" | cut -d : -f 4-
OK: 6 of 6 tests passed
$
```

For Markdown files with 4-spaces indented code blocks, use `--prefix 4`.

Of course, this [README.md](https://github.com/aureliojargas/cltest/blob/master/README.md) file you are now reading is also testable. Since it uses non-indented fenced code blocks (` ``` `), no prefix option is needed: `cltest README.md`.


## Alternative Syntax: Inline Output

Now a nice extension to the original idea. Using the special marker `#→` you can embed the expected command output at the end of the command line.

```
$ echo "foo"                      #→ foo
$ echo $((10 + 2))                #→ 12
```

This is the same as doing:

```
$ echo "foo"
foo
$ echo $((10 + 2))
12
$
```

Inline outputs are very readable when testing series of commands that result in short texts.

```
$ echo "abcdef" | cut -c 1        #→ a
$ echo "abcdef" | cut -c 4        #→ d
$ echo "abcdef" | cut -c 1,4      #→ ad
$ echo "abcdef" | cut -c 1-4      #→ abcd
```

> Note: The Unicode character `→` (U+2192) was chosen because it's meaningful and less likely to appear on a real command. If needed, you can change this marker (i.e., to `#->`) at the top of the script or using the `--inline-prefix` option.


## Advanced Tests

When using the `#→` marker, you can take advantage of special options to change the default output matching method.

```
$ head /etc/passwd            #→ --lines 10
$ tac /etc/passwd | tac       #→ --file /etc/passwd
$ cat /etc/passwd             #→ --egrep ^root:
$ echo $((2 + 10))            #→ --regex ^\d+$
$ pwd                         #→ --eval echo $PWD
```

* Using `#→ --lines` the test will pass if the command output has exactly `N` lines. Handy when the output text is variable (unpredictable), but the number of resulting lines is constant.

* Using `#→ --file` the test will pass if the command output matches the contents of an external file. Useful to organize long/complex outputs into files.

* Using `#→ --egrep` the test will pass if `egrep` matches at least one line of the command output.

* Using `#→ --regex` the test will pass if the command output is matched by a [Perl regular expression](http://perldoc.perl.org/perlre.html). A multiline output is matched as a single string, with inner `\n`'s. Use the `(?ims)` modifiers when needed.

* Using `#→ --eval` the test will pass if both commands result in the same output. Useful to expand variables which store the full or partial output.


## Options

```
$ cltest --help
Usage: cltest [options] <file ...>

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
      --inline-prefix PREFIX  Set inline output prefix (default: '#→ ')
      --prefix PREFIX         Set command line prefix (default: '')
      --prompt STRING         Set prompt string (default: '$ ')
$
```

When running sequential tests, where the next test depends on the correct result of the previous test, use the `--first` option to abort the execution if any test fails.

To rerun a specific problematic test, or to limit the execution to a set of tests, use `--test`. To ignore one or more tests, use `--skip`. If needed, you can combine both options to inform a very specific test range. Examples:

    cltest --test 1-10    tests.txt   # Run the first 10 tests
    cltest --test 1,2,6-8 tests.txt   # Run tests #1, #2, #6, #7 and #8
    cltest --skip 11,15   tests.txt   # Run all tests, except #11 and #15
    cltest -t 1-10 -s 5   tests.txt   # Run first 10 tests, but skip #5

You can run a preparing script or command before the first test with `--pre-flight`, for setting env variables and create auxiliary files. At the end of all tests, run a final cleanup script/command with `--post-flight` to remove temporary files or other transient data. Example:


    cltest --pre-flight ./test-init.sh --post-flight 'rm *.tmp' tests.txt

Use the customization options to extract and test command lines from documents or wiki pages. For example, to test all the command line examples listed inside a Markdown file using the 4-spaces syntax for code blocks:

    cltest --prefix 4 README.md

Or maybe you use a different prompt (`$PS1`) in your documentation?

    cltest  --prefix 4 --prompt '[john@localhost ~]$ ' README.md

When automating the tests execution, use `--quiet` to show no output and just check the exit code to make sure all tests have passed. Example:

    if cltest --quiet tests.txt
    then
        # all tests passed
    else
        # one or more tests failed :(
    fi


## Portability

This script was carefully coded to be portable between [POSIX](http://en.wikipedia.org/wiki/POSIX) shells.

It was tested in:

* Bash 3.2
* dash 0.5.5.1
* ksh 93u 2011-02-08

Portability issues are considered serious bugs, please [report them](https://github.com/aureliojargas/cltest/issues)!

Developers: Learn mode about portability in POSIX shells:

* [How to make bash scripts work in dash](http://mywiki.wooledge.org/Bashism)
* [Ubuntu — Dash as /bin/sh](https://wiki.ubuntu.com/DashAsBinSh)
* [Rich’s sh (POSIX shell) tricks](http://www.etalabs.net/sh_tricks.html)
* [lintsh](http://code.dogmap.org/lintsh/) 
* [Official POSIX specification: Shell & Utilities](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)


## KISS

* A shell script to test shell commands.
* No other language or environment involved.


## Meta

* Author:   [Aurelio Jargas](http://aurelio.net/about.html)
* Created:  2013-07-24
* Language: Shell Script
* License:  [MIT](https://github.com/aureliojargas/cltest/blob/master/LICENSE.txt)

