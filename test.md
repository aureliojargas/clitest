#  Test suite for clitest

This is the test file for the `clitest` program. Yes, the program can test itself!

This file runs all the files inside the `test` folder and checks the results. The command line options are also tested.

    Usage: ./clitest test.md


## Preparing

Make sure we're on the same folder as `clitest`, since all the file paths here are relative, not absolute.

```
$ test -f ./clitest; echo $?
0
$ test -d ./test/; echo $?
0
$
```

Set a default terminal width of 80 columns. It's used by separator lines.

```
$ shopt -u checkwinsize 2> /dev/null  # bash: disable automatic check
$ unset COLUMNS  # mksh: first unset, then one can manually set it
$ COLUMNS=80
$ export COLUMNS
$
```

Ok. Now the real tests begins.

## Variables are persistent between tests?

```
$ echo $COLUMNS
80
$ not_exported=1
$ echo $not_exported
1
$ echo $not_exported  #=> 1
$ echo $not_exported  #=> --regex ^1$
```

## Check the temporary dir creation

```
$ TMPDIR___SAVE="$TMPDIR"
$ TMPDIR=/notfound
$ export TMPDIR
$ ./clitest test/ok-1.sh 2>&1 | grep ^clitest | sed 's/clitest\..*$/clitest.XXXXXX/'
clitest: Error: cannot create temporary dir: /notfound/clitest.XXXXXX
$ TMPDIR="$TMPDIR___SAVE"
$
```

## I/O, file reading  (message and exit code)

Missing input file

```
$ ./clitest; echo $?
clitest: Error: no test file informed (try --help)
2
$ ./clitest --
clitest: Error: no test file informed (try --help)
$ ./clitest --list
clitest: Error: no test file informed (try --help)
$
```

File not found

```
$ ./clitest notfound; echo $?
clitest: Error: cannot read input file: notfound
2
$
```

File is a directory

```
$ ./clitest .
clitest: Error: input file is a directory: .
$ ./clitest ./
clitest: Error: input file is a directory: ./
$ ./clitest /etc
clitest: Error: input file is a directory: /etc
$
```

## No test found (message and exit code)

```
$ ./clitest test/no-test-found.sh; echo $?
clitest: Error: no test found in input file: test/no-test-found.sh
2
$ ./clitest test/empty-file.sh
clitest: Error: no test found in input file: test/empty-file.sh
$ ./clitest test/empty-prompt-file.sh
clitest: Error: no test found in input file: test/empty-prompt-file.sh
$ ./clitest test/empty-prompts-file.sh
clitest: Error: no test found in input file: test/empty-prompts-file.sh
$
```

## Option --version

The exit code must always be zero.

```
$ ./clitest --version > /dev/null; echo $?
0
$
```

Test the output text and the short option `-V`.

```
$ ./clitest --version
clitest 0.5.0
$ ./clitest -V
clitest 0.5.0
$
```

## Option --help

Test the full help text contents and the exit code (zero).

```
$ ./clitest --help; echo $?
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

See also: https://github.com/aureliojargas/clitest
0
$
```

The short option `-h` is working? Testing just the first and last lines for brevity.

```
$ ./clitest -h | sed -n '1p; $p'
Usage: clitest [options] <file ...>
See also: https://github.com/aureliojargas/clitest
$
```


## Option --quiet and exit code

```
$ ./clitest -q test/ok-2.sh; echo $?
0
$ ./clitest --quiet test/ok-2.sh; echo $?
0
$ ./clitest --quiet test/ok-2.sh test/ok-2.sh; echo $?
0
$ ./clitest --quiet test/fail-2.sh; echo $?
1
$ ./clitest --quiet test/fail-2.sh test/fail-2.sh; echo $?
1
$ ./clitest --quiet test/ok-2.sh test/fail-2.sh; echo $?
1
$
```

## Option --quiet has no effect in error messages

```
$ ./clitest --quiet notfound
clitest: Error: cannot read input file: notfound
$
```

## Option --quiet has no effect in --debug

```
$ ./clitest --debug --quiet test/ok-1.sh | grep -o INPUT_LINE
INPUT_LINE
INPUT_LINE
$
```

## Option --debug

Tricky test file with: empty line, inline marker, tab, $, comment line, normal command, unclosed block.

```
$ ./clitest --debug test/option-debug.sh
--------------------------------------------------------------------------------
-- INPUT_LINE[# Test file to be run with --debug]
--  LINE_MISC[# Test file to be run with --debug]
--------------------------------------------------------------------------------
-- INPUT_LINE[]
--  LINE_MISC[]
--------------------------------------------------------------------------------
-- INPUT_LINE[$ echo "tab+space	 "	 #=> tab+space	 ]
--   LINE_CMD[$ echo "tab+space<tab> "<tab> #=> tab+space<tab> ]
--    NEW_CMD[echo "tab+space<tab> "<tab> ]
--  OK_INLINE[tab+space<tab> ]
--    OK_TEXT[tab+space<tab> ]
#1	echo "tab+space	 "	 
--       EVAL[echo "tab+space<tab> "<tab> ]
--     OUTPUT[tab+space<tab> ]
--------------------------------------------------------------------------------
-- INPUT_LINE[$]
--     LINE_$[$]
--------------------------------------------------------------------------------
-- INPUT_LINE[# A comment line between command blocks]
--  LINE_MISC[# A comment line between command blocks]
--------------------------------------------------------------------------------
-- INPUT_LINE[$ echo "unclosed block"]
--   LINE_CMD[$ echo "unclosed block"]
--    NEW_CMD[echo "unclosed block"]
--------------------------------------------------------------------------------
-- INPUT_LINE[unclosed block]
--  LINE_MISC[unclosed block]
--    OK_TEXT[unclosed block]
--   LOOP_OUT[$tt_test_command=echo "unclosed block"]
#2	echo "unclosed block"
--       EVAL[echo "unclosed block"]
--     OUTPUT[unclosed block]
OK: 2 of 2 tests passed
$
```

## Option --debug with colors

- Separator line is cyan
- `INPUT_LINE[...]` is cyan, others are normal color inside `[]`
- `<tab>` must be green
- `#=>` inline marker must be red

This test forces `--color always` because normally the tests inside this file are not colored (output is not a terminal). Note that the escape character (`\033`) is removed to have only printable ASCII characters in the output.

```
$ ./clitest --debug --color always test/option-debug-color.sh | head -n 3 | tr -d '\033'
[36m--------------------------------------------------------------------------------[m
[36m-- INPUT_LINE[$ echo "tab	" #=> tab	][m
[36m--   LINE_CMD[[m$ echo "tab[32m<tab>[m" [31m#=> [mtab[32m<tab>[m[36m][m
$
```

In case of multiple `#=>`, only the last one should be red:

```
$ ./clitest --debug --color always test/inline-multiple-marker.sh | command grep LINE_CMD | tr -d '\033'
[36m--   LINE_CMD[[m$ echo "a #=> b #=> c"  #=> --lines 99 [31m#=> [m--lines 1[36m][m
$
```

## Option --color

Invalid value

```
$ ./clitest --color foo test/ok-1.sh; echo $?
clitest: Error: invalid value 'foo' for --color. Use: auto, always or never.
2
$
```

Color ON

> Note that the escape character (`\033`) is removed to have only printable ASCII characters in the output.

```
$ ./clitest --color always test/ok-1.sh | tr -d '\033'
#1	echo ok
[32mOK:[m 1 of 1 test passed
$ ./clitest --color yes test/ok-1.sh | tr -d '\033'
#1	echo ok
[32mOK:[m 1 of 1 test passed
$
```

Color OFF

```
$ ./clitest --color never test/ok-1.sh
#1	echo ok
OK: 1 of 1 test passed
$ ./clitest --color no test/ok-1.sh
#1	echo ok
OK: 1 of 1 test passed
$
```

Color AUTO

Inside this file, the output is not a terminal,
so the default is no colored output.

```
$ ./clitest test/ok-1.sh
#1	echo ok
OK: 1 of 1 test passed
$
```

The real default `--color auto` cannot be tested here.
Test it by hand at the command line.

## Option --list

Listing a file with no tests

```
$ ./clitest --list test/empty-file.sh; echo $?
clitest: Error: no test found in input file: test/empty-file.sh
2
$
```

Normal results and exit code

```
$ ./clitest --list test/no-nl-command.sh; echo $?
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
#7	printf 'ok'         
0
$
```

Short option `-l`

```
$ ./clitest -l test/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
#7	printf 'ok'         
$
```

Multifile and exit code

```
$ ./clitest --list test/no-nl-command.sh test/ok-1.sh; echo $?
---------------------------------------- test/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
#7	printf 'ok'         
---------------------------------------- test/ok-1.sh
#8	echo ok
0
$
```

## Option --list-run

Listing a file with no tests

```
$ ./clitest --list-run test/empty-file.sh; echo $?
clitest: Error: no test found in input file: test/empty-file.sh
2
$
```

Normal results (using colors) and exit code

> Note that the escape character (`\033`) is removed to have only printable ASCII characters in the output.

```
$ ./clitest --list-run --color always test/no-nl-command.sh > /tmp/foo.txt; echo $?
1
$ cat /tmp/foo.txt | tr -d '\033'
[32m#1	printf 'ok\n'[m
[31m#2	printf 'fail'[m
[31m#3	printf 'ok\nok\nfail'[m
[32m#4	printf 'ok\n'    [m
[31m#5	printf 'fail'    [m
[32m#6	printf 'ok'; echo   [m
[32m#7	printf 'ok'         [m
$ rm /tmp/foo.txt
$
```

Normal results (no colors, use OK/FAIL column) and exit code

```
$ ./clitest --list-run test/no-nl-command.sh; echo $?
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
#7	OK	printf 'ok'         
1
$
```

Short option `-L`

```
$ ./clitest -L test/no-nl-command.sh
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
#7	OK	printf 'ok'         
$
```

Multifile and exit code

```
$ ./clitest -L test/no-nl-command.sh test/ok-1.sh; echo $?
---------------------------------------- test/no-nl-command.sh
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
#7	OK	printf 'ok'         
---------------------------------------- test/ok-1.sh
#8	OK	echo ok
1
$ ./clitest -L test/ok-1.sh; echo $?
#1	OK	echo ok
0
$
```

## Option --progress

First, some invalid values:

```
$ ./clitest --progress test/ok-1.sh
clitest: Error: no test file informed (try --help)
$ ./clitest --progress '' test/ok-1.sh
clitest: Error: invalid value '' for --progress. Use: test, number, dot or none.
$ ./clitest --progress foo test/ok-1.sh
clitest: Error: invalid value 'foo' for --progress. Use: test, number, dot or none.
$ ./clitest --progress DOT test/ok-1.sh
clitest: Error: invalid value 'DOT' for --progress. Use: test, number, dot or none.
$ ./clitest --progress @@ test/ok-1.sh
clitest: Error: invalid value '@@' for --progress. Use: test, number, dot or none.
$ ./clitest --progress -1 test/ok-1.sh; echo $?
clitest: Error: invalid value '-1' for --progress. Use: test, number, dot or none.
2
$
```

If no `--progress` option, defaults to `--progress test`:

```
 $ ./clitest test/ok-1.sh
 #1	echo ok
 OK: 1 of 1 test passed
 $ ./clitest --progress test test/ok-1.sh
 #1	echo ok
 OK: 1 of 1 test passed
 $
```

Numbers:

```
$ ./clitest --progress number test/ok-10.sh
1 2 3 4 5 6 7 8 9 10 
OK: 10 of 10 tests passed
$ ./clitest --progress n test/ok-10.sh
1 2 3 4 5 6 7 8 9 10 
OK: 10 of 10 tests passed
$ ./clitest --progress 0 test/ok-10.sh
1 2 3 4 5 6 7 8 9 10 
OK: 10 of 10 tests passed
$ ./clitest --progress 5 test/ok-10.sh
1 2 3 4 5 6 7 8 9 10 
OK: 10 of 10 tests passed
$ ./clitest --progress 9 test/ok-10.sh
1 2 3 4 5 6 7 8 9 10 
OK: 10 of 10 tests passed
$
```

Chars:

```
$ ./clitest --progress dot test/ok-10.sh
..........
OK: 10 of 10 tests passed
$ ./clitest --progress . test/ok-10.sh
..........
OK: 10 of 10 tests passed
$ ./clitest --progress @ test/ok-10.sh
@@@@@@@@@@
OK: 10 of 10 tests passed
$ ./clitest --progress x test/ok-10.sh
xxxxxxxxxx
OK: 10 of 10 tests passed
$
```

No progress:

```
$ ./clitest --progress none test/ok-1.sh
OK: 1 of 1 test passed
$ ./clitest --progress no test/ok-1.sh
OK: 1 of 1 test passed
$
```

Short option `-P`:

```
$ ./clitest -P dot test/ok-1.sh
.
OK: 1 of 1 test passed
$ ./clitest -P no test/ok-1.sh
OK: 1 of 1 test passed
$
```

Ok & fail functionality with dot:

```
$ ./clitest --progress . test/ok-1.sh
.
OK: 1 of 1 test passed
$ ./clitest --progress . test/ok-2.sh
..
OK: 2 of 2 tests passed
$ ./clitest --progress . test/ok-50.sh
..................................................
OK: 50 of 50 tests passed
$ ./clitest --progress . test/fail-1.sh
.
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 1 of 1 test failed
$
```

Multifile with dot:

```
$ ./clitest --progress . test/ok-1.sh test/ok-2.sh test/ok-10.sh
Testing file test/ok-1.sh .
Testing file test/ok-2.sh ..
Testing file test/ok-10.sh ..........

     ok  fail  skip
      1     -     -    test/ok-1.sh
      2     -     -    test/ok-2.sh
     10     -     -    test/ok-10.sh

OK: 13 of 13 tests passed
$ ./clitest --progress . test/ok-1.sh test/fail-1.sh
Testing file test/ok-1.sh .
Testing file test/fail-1.sh .
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     1     -    test/fail-1.sh

FAIL: 1 of 2 tests failed
$ ./clitest --progress . test/fail-1.sh test/ok-1.sh
Testing file test/fail-1.sh .
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file test/ok-1.sh .

     ok  fail  skip
      -     1     -    test/fail-1.sh
      1     -     -    test/ok-1.sh

FAIL: 1 of 2 tests failed
$
```

Multifile with no progress:

```
$ ./clitest --progress none test/ok-1.sh test/ok-2.sh test/ok-10.sh
Testing file test/ok-1.sh
Testing file test/ok-2.sh
Testing file test/ok-10.sh

     ok  fail  skip
      1     -     -    test/ok-1.sh
      2     -     -    test/ok-2.sh
     10     -     -    test/ok-10.sh

OK: 13 of 13 tests passed
$ ./clitest --progress none test/ok-1.sh test/fail-1.sh
Testing file test/ok-1.sh
Testing file test/fail-1.sh
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     1     -    test/fail-1.sh

FAIL: 1 of 2 tests failed
$ ./clitest --progress none test/fail-1.sh test/ok-1.sh
Testing file test/fail-1.sh
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file test/ok-1.sh

     ok  fail  skip
      -     1     -    test/fail-1.sh
      1     -     -    test/ok-1.sh

FAIL: 1 of 2 tests failed
$
```

### Option --progress and skipped tests

Since skipped tests affect the output (show nothing), it's worth
testing if the line break issues won't appear.

```
$ ./clitest --progress . --skip 1 test/ok-2.sh
.
OK: 1 of 2 tests passed (1 skipped)
$ ./clitest --progress . --skip 2 test/ok-2.sh
.
OK: 1 of 2 tests passed (1 skipped)
$ ./clitest --progress . --skip 1 test/fail-2.sh
.
--------------------------------------------------------------------------------
[FAILED #2, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 1 of 2 tests failed (1 skipped)
$ ./clitest --progress . --skip 2 test/fail-2.sh
.
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 1 of 2 tests failed (1 skipped)
$
```

Error messages appear with no leading blank line?

```
$ ./clitest --progress . --skip 1,2 test/ok-2.sh
clitest: Error: no test found. Maybe '--skip 1,2' was too much?
$
```


## Options --quiet, --progress, --list and --list-run are mutually exclusive

* Only one can be active, the others must be off.
* The last informed will be the one used.

```
$ ./clitest --list --quiet test/ok-1.sh
$ ./clitest --list-run --quiet test/ok-1.sh
$ ./clitest --progress . --quiet test/ok-1.sh
$ ./clitest --list --list-run --progress . --quiet test/ok-1.sh
$ ./clitest --quiet --progress . --list-run --list test/ok-1.sh
#1	echo ok
$ ./clitest --quiet --progress . --list --list-run test/ok-1.sh
#1	OK	echo ok
$ ./clitest --quiet --list --list-run --progress . test/ok-1.sh
.
OK: 1 of 1 test passed
$
```

## Option --test and --skip combined with --list and --list-run

Error: Out of range

```
$ ./clitest --list -t 99 test/ok-10.sh
clitest: Error: no test found for the specified number or range '99'
$ ./clitest --list-run -t 99 test/ok-10.sh; echo $?
clitest: Error: no test found for the specified number or range '99'
2
$
```

Error: Skipped all tests

```
$ ./clitest --list -s 1-10 test/ok-10.sh
clitest: Error: no test found. Maybe '--skip 1-10' was too much?
$ ./clitest --list-run -s 1-10 test/ok-10.sh; echo $?
clitest: Error: no test found. Maybe '--skip 1-10' was too much?
2
$
```

Error: The combination of `-t` and `-s` resulted in no tests

```
$ ./clitest --list -t 9 -s 9 test/ok-10.sh
clitest: Error: no test found. The combination of -t and -s resulted in no tests.
$ ./clitest --list-run -t 9 -s 9 test/ok-10.sh; echo $?
clitest: Error: no test found. The combination of -t and -s resulted in no tests.
2
$
```

Using `-t` alone

```
$ ./clitest --list -t 3,5-7 test/ok-10.sh
#3	echo 3 
#5	echo 5 
#6	echo 6 
#7	echo 7 
$ ./clitest --list-run -t 3,5-7 test/ok-10.sh
#3	OK	echo 3 
#5	OK	echo 5 
#6	OK	echo 6 
#7	OK	echo 7 
$
```

Reverse ranges and repeated numbers are supported

```
$ ./clitest --list -t 3,7-5,3,6,5 test/ok-10.sh
#3	echo 3 
#5	echo 5 
#6	echo 6 
#7	echo 7 
$
```

Using `-t` to limit to a range and the `-s` exclude some more

```
$ ./clitest --list -t 3,5-7 -s 6 test/ok-10.sh
#3	echo 3 
#5	echo 5 
#7	echo 7 
$ ./clitest --list-run -t 3,5-7 -s 6 test/ok-10.sh
#3	OK	echo 3 
#5	OK	echo 5 
#7	OK	echo 7 
$
```

Multifile, using `-t` alone


```
$ ./clitest --list -t 1,3,5-7 test/ok-1.sh test/fail-2.sh test/ok-10.sh
---------------------------------------- test/ok-1.sh
#1	echo ok
---------------------------------------- test/fail-2.sh
#3	echo ok  
---------------------------------------- test/ok-10.sh
#5	echo 2 
#6	echo 3 
#7	echo 4 
$ ./clitest --list-run -t 1,3,5-7 test/ok-1.sh test/fail-2.sh test/ok-10.sh
---------------------------------------- test/ok-1.sh
#1	OK	echo ok
---------------------------------------- test/fail-2.sh
#3	FAIL	echo ok  
---------------------------------------- test/ok-10.sh
#5	OK	echo 2 
#6	OK	echo 3 
#7	OK	echo 4 
$
```

Multifile, using `-t` and `-s`

```
$ ./clitest --list -t 1,3,5-7 -s 3,6 test/ok-1.sh test/fail-2.sh test/ok-10.sh
---------------------------------------- test/ok-1.sh
#1	echo ok
---------------------------------------- test/fail-2.sh
---------------------------------------- test/ok-10.sh
#5	echo 2 
#7	echo 4 
$ ./clitest --list-run -t 1,3,5-7 -s 3,6 test/ok-1.sh test/fail-2.sh test/ok-10.sh
---------------------------------------- test/ok-1.sh
#1	OK	echo ok
---------------------------------------- test/fail-2.sh
---------------------------------------- test/ok-10.sh
#5	OK	echo 2 
#7	OK	echo 4 
$
```

## Single file, OK

```
$ ./clitest test/ok-1.sh
#1	echo ok
OK: 1 of 1 test passed
$ ./clitest test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$ ./clitest test/ok-50.sh | tail -1
OK: 50 of 50 tests passed
$ ./clitest test/ok-100.sh | tail -1
OK: 100 of 100 tests passed
$ ./clitest test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

## Multifile, all OK

```
$ ./clitest test/ok-2.sh test/ok-2.sh
Testing file test/ok-2.sh
#1	echo ok
#2	echo ok  
Testing file test/ok-2.sh
#3	echo ok
#4	echo ok  

     ok  fail  skip
      2     -     -    test/ok-2.sh
      2     -     -    test/ok-2.sh

OK: 4 of 4 tests passed
$ ./clitest test/ok-1.sh test/ok-10.sh test/ok-100.sh test/ok-50.sh | grep -v ^#
Testing file test/ok-1.sh
Testing file test/ok-10.sh
Testing file test/ok-100.sh
Testing file test/ok-50.sh

     ok  fail  skip
      1     -     -    test/ok-1.sh
     10     -     -    test/ok-10.sh
    100     -     -    test/ok-100.sh
     50     -     -    test/ok-50.sh

OK: 161 of 161 tests passed
$ ./clitest test/ok-?.sh test/ok-10.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
#2	echo ok
#3	echo ok  
Testing file test/ok-10.sh
#4	echo 1 
#5	echo 2 
#6	echo 3 
#7	echo 4 
#8	echo 5 
#9	echo 6 
#10	echo 7 
#11	echo 8 
#12	echo 9 
#13	echo 10 

     ok  fail  skip
      1     -     -    test/ok-1.sh
      2     -     -    test/ok-2.sh
     10     -     -    test/ok-10.sh

OK: 13 of 13 tests passed
$
```

## Multifile, OK and fail

```
$ ./clitest test/ok-1.sh test/fail-1.sh test/ok-2.sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/fail-1.sh
#2	echo ok
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file test/ok-2.sh
#3	echo ok
#4	echo ok  
Testing file test/fail-2.sh
#5	echo ok
--------------------------------------------------------------------------------
[FAILED #5, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#6	echo ok  
--------------------------------------------------------------------------------
[FAILED #6, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     1     -    test/fail-1.sh
      2     -     -    test/ok-2.sh
      -     2     -    test/fail-2.sh

FAIL: 3 of 6 tests failed
$ ./clitest test/ok-1.sh test/fail-1.sh test/ok-2.sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/fail-1.sh
#2	echo ok
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file test/ok-2.sh
#3	echo ok
#4	echo ok  
Testing file test/fail-2.sh
#5	echo ok
--------------------------------------------------------------------------------
[FAILED #5, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#6	echo ok  
--------------------------------------------------------------------------------
[FAILED #6, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     1     -    test/fail-1.sh
      2     -     -    test/ok-2.sh
      -     2     -    test/fail-2.sh

FAIL: 3 of 6 tests failed
$
```

## Fail messages

```
$ ./clitest --prefix tab -P none test/fail-messages.md  #=> --file test/fail-messages.out.txt
$
```

## Fails

```
$ ./clitest test/fail-1.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 1 of 1 test failed
$ ./clitest test/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#2	echo ok  
--------------------------------------------------------------------------------
[FAILED #2, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$ ./clitest test/fail-50.sh | tail -1
FAIL: 50 of 50 tests failed
$ ./clitest -1 test/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./clitest --first test/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./clitest --first test/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./clitest test/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#2	echo ok  
--------------------------------------------------------------------------------
[FAILED #2, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$
```

## Inline output with #=>

```
$ ./clitest test/inline.sh
#1	echo 'one space' 
#2	echo 'one tab'	
#3	echo 'multi spaces'           
#4	echo 'multi tabs'				
#5	echo 'mixed'  	 		 	
#6	echo ' leading space' 
#7	echo '    leading spaces' 
#8	printf '\tleading tab\n' 
#9	printf '\t\tleading tabs\n' 
#10	echo 'trailing space ' 
#11	echo 'trailing spaces    ' 
#12	printf 'trailing tab\t\n' 
#13	printf 'trailing tabs\t\t\n' 
#14	echo ' ' 
#15	echo '    ' 
#16	printf '\t\n' 
#17	printf '\t\t\t\n' 
#18	printf ' \t  \t\t   \n' 
#19	echo "both inline and normal output"  
OK: 19 of 19 tests passed
$
```

In case of multiple `#=>`, consider only the last one:

```
$ ./clitest test/inline-multiple-marker.sh
#1	echo "a #=> b #=> c"  #=> --lines 99 
OK: 1 of 1 test passed
$

## Inline match modes

Mode #=> --text

* This is the default mode.
* The --text part can be omitted.

```
$ ./clitest --list-run test/inline-match-text.sh
#1	OK	echo 'abc'                    
#2	OK	echo 'abc'                    
#3	OK	printf '%s\n' '\t'            
#4	OK	printf '%s\n' '\n'            
#5	OK	echo '$PWD'                   
#6	OK	echo '$(date)'                
#7	OK	echo '$'                      
#8	OK	echo '>'                      
#9	OK	echo '?'                      
#10	OK	echo '!'                      
#11	OK	echo '*'                      
#12	OK	echo '['                      
#13	OK	echo '('                      
#14	OK	echo                          
#15	OK	echo "not inline output"      #=>
#16	OK	echo '123456789'              
#17	OK	echo '1 3   7 9'              
#18	OK	echo '    5    '              
#19	OK	echo ' leading space'         
#20	OK	echo '    leading spaces'     
#21	OK	printf '\tleading tab\n'      
#22	OK	printf '\t\tleading tabs\n'   
#23	OK	echo 'trailing space '        
#24	OK	echo 'trailing spaces    '    
#25	OK	printf 'trailing tab\t\n'     
#26	OK	printf 'trailing tabs\t\t\n'  
#27	OK	echo ' '                      
#28	FAIL	echo '   '                    
#29	OK	printf '\t\n'                 
#30	OK	printf '\t\t\t\n'             
#31	OK	printf ' \t  \t\t   \n'       
#32	OK	printf 'ok\n'                 
#33	FAIL	printf 'fail'                 
#34	OK	printf 'ok'; echo             
#35	FAIL	echo 'fail'                   
#36	FAIL	echo 'fail'                   
#37	OK	echo ' ok'                    
#38	OK	echo '--text'                 
#39	OK	echo '--textual'              
#40	OK	echo '--text is cool'         
$
```

Mode #=> --eval

```
$ ./clitest --list-run test/inline-match-eval.sh
#1	OK	folder=$(pwd)
#2	OK	echo $folder                  
#3	OK	var='abc'
#4	OK	echo abc                      
#5	OK	echo 4                        
#6	OK	today=$(date +%D)
#7	OK	echo "Today is $today"        
#8	OK	printf 'ok'                   
#9	OK	echo ' leading space'         
#10	OK	echo '    leading spaces'     
#11	OK	printf '\tleading tab\n'      
#12	OK	printf '\t\tleading tabs\n'   
#13	OK	echo 'trailing space '        
#14	OK	echo 'trailing spaces    '    
#15	OK	printf 'trailing tab\t\n'     
#16	OK	printf 'trailing tabs\t\t\n'  
#17	OK	echo ' '                      
#18	OK	echo '   '                    
#19	OK	printf '\t\n'                 
#20	OK	printf '\t\t\t\n'             
#21	OK	printf ' \t  \t\t   \n'       
#22	FAIL	echo 'fail'                   
#23	FAIL	echo 'fail'                   
#24	OK	echo '--eval'                 
#25	OK	echo '--evaluate'             
#26	OK	echo '--eval is evil'         
$
```

Mode #=> --egrep

```
$ ./clitest --list-run test/inline-match-egrep.sh
#1	OK	echo 'abc123'                 
#2	OK	echo 'abc123'                 
#3	OK	echo 'abc123'                 
#4	OK	echo 'abc123'                 
#5	OK	echo 'abc123'                 
#6	OK	echo 'abc123'                 
#7	OK	echo 'abc123'                 
#8	OK	echo 'abc123'                 
#9	OK	echo 'abc 123'                
#10	OK	echo ' '                      
#11	OK	echo '    '                   
#12	OK	printf '\t\n'                 
#13	OK	printf '\t\t\t\n'             
#14	OK	printf ' \t  \t\t   \n'       
#15	OK	printf 'will\tmatch'          
#16	FAIL	printf 'will\nfail'           
#17	OK	printf '1\n2\n3\n4\nok\n'     
#18	OK	printf 'ok'                   
#19	OK	printf 'ok\n'                 
#20	FAIL	echo 'fail'                   
#21	FAIL	echo 'fail'                   
#22	OK	echo ' ok'                    
#23	OK	echo '--egrep'                
#24	OK	echo '--egreppal'             
#25	OK	echo '--egrep is cool'        
$
```

Mode #=> --perl

* --regex is an alias to --perl

```
$ ./clitest --list-run test/inline-match-perl.sh
#1	OK	echo 'abc123'                 
#2	OK	echo 'abc123'                 
#3	OK	echo 'abc123'                 
#4	OK	echo 'abc123'                 
#5	OK	echo 'abc123'                 
#6	OK	echo 'abc123'                 
#7	OK	echo 'abc123'                 
#8	OK	echo 'abc123'                 
#9	OK	echo 'abc 123'                
#10	OK	echo ' '                      
#11	OK	echo '    '                   
#12	OK	printf '\t\n'                 
#13	OK	printf '\t\t\t\n'             
#14	OK	printf ' \t  \t\t   \n'       
#15	OK	echo '01/01/2013'             
#16	OK	echo "won't fail"             
#17	OK	printf 'will\tmatch'          
#18	OK	printf 'will\tmatch'          
#19	OK	printf 'will\tmatch'          
#20	FAIL	printf 'will\nfail'           
#21	OK	printf 'will\nmatch'          
#22	FAIL	printf 'will\nfail'           
#23	OK	printf 'will\nmatch'          
#24	FAIL	printf 'will\nfail'           
#25	OK	printf 'will\nmatch'          
#26	OK	printf 'ok'                   
#27	OK	printf 'ok\n'                 
#28	OK	printf '1\n2\n3\n'            
#29	OK	printf '1\n2\n3\n'            
#30	FAIL	echo 'fail'                   
#31	FAIL	echo 'fail'                   
#32	OK	echo ' ok'                    
#33	OK	echo '--perl'                 
#34	OK	echo '--perlism'              
#35	OK	echo '--perl is cool'         
$
```

Mode #=> --file

```
$ ./clitest --list-run test/inline-match-file.sh
#1	OK	printf '$ echo ok\nok\n'      
#2	OK	echo 'ok' > /tmp/foo.txt
#3	OK	echo 'ok'                     
#4	OK	rm /tmp/foo.txt
#5	FAIL	echo 'fail'                   
#6	FAIL	echo 'fail'                   
#7	OK	echo '--file'                 
#8	OK	echo '--filer'                
#9	OK	echo '--file is cool'         
$
```

Mode #=> --lines

```
$ ./clitest --list-run test/inline-match-lines.sh
#1	OK	a=1                           
#2	OK	echo 'ok'                     
#3	OK	printf '1\n2\n3\n'            
#4	OK	printf 'no-nl'                
#5	OK	printf '1\n2\nno-nl'          
#6	FAIL	echo 'fail'                   
#7	FAIL	echo 'fail'                   
#8	FAIL	echo 'fail'                   
#9	FAIL	echo 'fail'                   
#10	OK	echo '--lines'                 
#11	OK	echo '--linesout'             
#12	OK	echo '--lines is cool'         
$ ./clitest --first test/inline-match-lines.sh
#1	a=1                           
#2	echo 'ok'                     
#3	printf '1\n2\n3\n'            
#4	printf 'no-nl'                
#5	printf '1\n2\nno-nl'          
#6	echo 'fail'                   
--------------------------------------------------------------------------------
[FAILED #6, line 16] echo 'fail'                   
Expected 99 lines, got 1.
--------------------------------------------------------------------------------
$
```

Mode #=> --exit

```
$ ./clitest --list-run test/inline-match-exit.sh
#1	OK	true                          
#2	OK	false                         
#3	OK	sh -c 'exit 3'                
#4	OK	command-not-found             
#5	OK	echo "STDOUT ignored"         
#6	OK	cut                           
#7	OK	echo "STDOUT ignored"         
#8	OK	cut                           
#9	FAIL	echo 'fail'                   
#10	FAIL	echo 'fail'                   
#11	FAIL	echo 'fail'                   
#12	OK	echo '--exit'                 
#13	OK	echo '--exitout'             
#14	OK	echo '--exit is cool'         
$ ./clitest --first test/inline-match-exit.sh 
#1	true                          
#2	false                         
#3	sh -c 'exit 3'                
#4	command-not-found             
#5	echo "STDOUT ignored"         
#6	cut                           
#7	echo "STDOUT ignored"         
#8	cut                           
#9	echo 'fail'                   
--------------------------------------------------------------------------------
[FAILED #9, line 25] echo 'fail'                   
Expected exit code 99, got 0
--------------------------------------------------------------------------------
$
```

Errors for #=> --egrep

```
$ ./clitest test/inline-match-egrep-error-1.sh; echo $?
clitest: Error: empty --egrep at line 1 of test/inline-match-egrep-error-1.sh
2
$ ./clitest test/inline-match-egrep-error-2.sh 2>&1 | sed 's/^e*grep: .*/egrep: ERROR_MSG/'
#1	echo "error: malformed regex"  
egrep: ERROR_MSG
clitest: Error: check your inline egrep regex at line 1 of test/inline-match-egrep-error-2.sh
$
```

Errors for #=> --perl (and --regex)

```
$ ./clitest test/inline-match-perl-error-1.sh; echo $?
clitest: Error: empty --perl at line 1 of test/inline-match-perl-error-1.sh
2
$ ./clitest test/inline-match-perl-error-2.sh
#1	echo "error: malformed regex"  
Unmatched ( in regex; marked by <-- HERE in m/( <-- HERE / at -e line 1.
clitest: Error: check your inline Perl regex at line 1 of test/inline-match-perl-error-2.sh
$
```

Errors for #=> --file

```
$ ./clitest test/inline-match-file-error-1.sh; echo $?
clitest: Error: empty --file at line 1 of test/inline-match-file-error-1.sh
2
$ ./clitest test/inline-match-file-error-2.sh; echo $?
#1	echo "error: file not found"  
clitest: Error: cannot read inline output file 'test/notfound', from line 1 of test/inline-match-file-error-2.sh
2
$ ./clitest test/inline-match-file-error-3.sh; echo $?
#1	echo "error: directory"  
clitest: Error: cannot read inline output file '/etc/', from line 1 of test/inline-match-file-error-3.sh
2
$
```

Errors for #=> --lines

```
$ ./clitest test/inline-match-lines-error-1.sh
clitest: Error: --lines requires a number. See line 1 of test/inline-match-lines-error-1.sh
$ ./clitest test/inline-match-lines-error-2.sh
clitest: Error: --lines requires a number. See line 1 of test/inline-match-lines-error-2.sh
$ ./clitest test/inline-match-lines-error-3.sh
clitest: Error: --lines requires a number. See line 1 of test/inline-match-lines-error-3.sh
$ ./clitest test/inline-match-lines-error-4.sh; echo $?
clitest: Error: --lines requires a number. See line 1 of test/inline-match-lines-error-4.sh
2
$
```

Errors for #=> --exit

```
$ ./clitest test/inline-match-exit-error-1.sh
clitest: Error: --exit requires a number. See line 1 of test/inline-match-exit-error-1.sh
$ ./clitest test/inline-match-exit-error-2.sh
clitest: Error: --exit requires a number. See line 1 of test/inline-match-exit-error-2.sh
$ ./clitest test/inline-match-exit-error-3.sh
clitest: Error: --exit requires a number. See line 1 of test/inline-match-exit-error-3.sh
$ ./clitest test/inline-match-exit-error-4.sh; echo $?
clitest: Error: --exit requires a number. See line 1 of test/inline-match-exit-error-4.sh
2
$
```

Errors for #=> --eval

```
$ ./clitest test/inline-match-eval-error-1.sh; echo $?
clitest: Error: empty --eval at line 1 of test/inline-match-eval-error-1.sh
2
$
```

## Option -t, --test

Error: Invalid argument

```
$ ./clitest -t - test/ok-2.sh
clitest: Error: invalid argument for -t or --test: -
$ ./clitest -t -1 test/ok-2.sh
clitest: Error: invalid argument for -t or --test: -1
$ ./clitest -t 1- test/ok-2.sh
clitest: Error: invalid argument for -t or --test: 1-
$ ./clitest -t 1--2 test/ok-2.sh
clitest: Error: invalid argument for -t or --test: 1--2
$ ./clitest -t 1-2-3 test/ok-2.sh; echo $?
clitest: Error: invalid argument for -t or --test: 1-2-3
2
$
```

Error: Out of range

```
$ ./clitest -t 99 test/ok-2.sh; echo $?
clitest: Error: no test found for the specified number or range '99'
2
$
```

If range = zero or empty, run all tests

```
$ ./clitest -t '' test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$ ./clitest -t 0 test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

* Empty values inside range are ignored
* The bogus `0-0` range is ignored
* The resulting range is zero

```
$ ./clitest -t ,,,0,0-0,,, test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

Normal operation, using `--test` and `-t`

```
$ ./clitest -t 1 test/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./clitest --test 1 test/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$
```

Ranges `0-1` and `1-0` expand to `1`

```
$ ./clitest -t 0-1,1-0 test/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$
```

Range `1-1` expand to `1`

```
$ ./clitest -t 1-1 test/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$
```

Repeated values are OK

```
$ ./clitest -t 1,1,1,0,1 test/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$
```

Range terminator is out of bounds

```
$ ./clitest -t 10-20 test/ok-10.sh
#10	echo 10 
OK: 1 of 10 tests passed (9 skipped)
$
```

Inverted ranges

```
$ ./clitest -t 3,2,1 test/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./clitest -t 3-1 test/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$
```

Multifile. The test numbers always increase sequentially, regardless of the file changes.

```
$ ./clitest -t 1,5,13 test/ok-?.sh test/ok-10.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/ok-10.sh
#5	echo 2 
#13	echo 10 

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      2     -     8    test/ok-10.sh

OK: 3 of 13 tests passed (10 skipped)
$ ./clitest -t 1,5 test/ok-[12].sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/fail-2.sh
#5	echo ok  
--------------------------------------------------------------------------------
[FAILED #5, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      -     1     1    test/fail-2.sh

FAIL: 1 of 5 tests failed (3 skipped)
$ ./clitest -t 1 test/ok-[12].sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/fail-2.sh

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      -     -     2    test/fail-2.sh

OK: 1 of 5 tests passed (4 skipped)
$
```

## Option -s, --skip

Error: Invalid argument

```
$ ./clitest -s - test/ok-2.sh
clitest: Error: invalid argument for -s or --skip: -
$ ./clitest -s -1 test/ok-2.sh
clitest: Error: invalid argument for -s or --skip: -1
$ ./clitest -s 1- test/ok-2.sh
clitest: Error: invalid argument for -s or --skip: 1-
$ ./clitest -s 1--2 test/ok-2.sh
clitest: Error: invalid argument for -s or --skip: 1--2
$ ./clitest -s 1-2-3 test/ok-2.sh; echo $?
clitest: Error: invalid argument for -s or --skip: 1-2-3
2
$
```

Error: Skipped all tests

```
$ ./clitest -s 1 test/ok-1.sh; echo $?
clitest: Error: no test found. Maybe '--skip 1' was too much?
2
$
```

Out of range: no problem, you just skipped a non-existent test. All tests will be run.

```
$ ./clitest -s 99 test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

If range = zero or empty, run all tests

```
$ ./clitest -s '' test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$ ./clitest -s 0 test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

* Empty values inside range are ignored
* The bogus `0-0` range is ignored
* The resulting range is zero

```
$ ./clitest -s ,,,0,0-0,,, test/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

Normal operation, using `--skip` and `-s`

```
$ ./clitest -s 1 test/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./clitest --skip 1 test/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$
```

Ranges `0-1` and `1-0` expand to `1`

```
$ ./clitest -s 0-1,1-0 test/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$
```

Range `1-1` expand to `1`

```
$ ./clitest -s 1-1 test/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$
```

Repeated values are OK

```
$ ./clitest -s 1,1,1,0,1 test/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$
```

Range terminator is out of bounds

```
$ ./clitest -s 2-10 test/ok-2.sh
#1	echo ok
OK: 1 of 2 tests passed (1 skipped)
$
```

Inverted ranges

```
$ ./clitest -s 10,9,8,7,6,5,4 test/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./clitest -s 10-4 test/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$
```

Multifile. The test numbers always increase sequentially, regardless of the file changes.

```
$ ./clitest -s 2,3,13 test/ok-?.sh test/ok-10.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/ok-10.sh
#4	echo 1 
#5	echo 2 
#6	echo 3 
#7	echo 4 
#8	echo 5 
#9	echo 6 
#10	echo 7 
#11	echo 8 
#12	echo 9 

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      9     -     1    test/ok-10.sh

OK: 10 of 13 tests passed (3 skipped)
$ ./clitest -s 2,3,4 test/ok-[12].sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/fail-2.sh
#5	echo ok  
--------------------------------------------------------------------------------
[FAILED #5, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      -     1     1    test/fail-2.sh

FAIL: 1 of 5 tests failed (3 skipped)
$ ./clitest -s 2-10 test/ok-[12].sh test/fail-2.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/ok-2.sh
Testing file test/fail-2.sh

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/ok-2.sh
      -     -     2    test/fail-2.sh

OK: 1 of 5 tests passed (4 skipped)
$
```

## Option --test combined with --skip

Error: The combination of `-t` and `-s` resulted in no tests

```
$ ./clitest -t 9 -s 9 test/ok-10.sh; echo $?
clitest: Error: no test found. The combination of -t and -s resulted in no tests.
2
$
```

The order does not matter, `-s` always wins

```
$ ./clitest -s 9 -t 9 test/ok-10.sh
clitest: Error: no test found. The combination of -t and -s resulted in no tests.
$
```

Using `-t` to limit to a range and the `-s` exclude some more

```
$ ./clitest -t 3,5-7 -s 6 test/ok-10.sh
#3	echo 3 
#5	echo 5 
#7	echo 7 
OK: 3 of 10 tests passed (7 skipped)
$
```

Same as previous, but now multifile

```
$ ./clitest -t 1,3,5-7 -s 3,6 test/ok-1.sh test/fail-2.sh test/ok-10.sh
Testing file test/ok-1.sh
#1	echo ok
Testing file test/fail-2.sh
Testing file test/ok-10.sh
#5	echo 2 
#7	echo 4 

     ok  fail  skip
      1     -     -    test/ok-1.sh
      -     -     2    test/fail-2.sh
      2     -     8    test/ok-10.sh

OK: 3 of 13 tests passed (10 skipped)
$
```

## Option --diff-options

```
$ ./clitest test/option-diff-options.sh
#1	echo "	diff -w to ignore spaces    "
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "	diff -w to ignore spaces    "
@@ -1 +1 @@
-diff -w    to ignore    spaces
+	diff -w to ignore spaces    
--------------------------------------------------------------------------------
#2	echo "	diff -w now inline    "  
--------------------------------------------------------------------------------
[FAILED #2, line 5] echo "	diff -w now inline    "  
@@ -1 +1 @@
-diff    -w    now    inline
+	diff -w now inline    
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$ ./clitest --diff-options '-u -w' test/option-diff-options.sh
#1	echo "	diff -w to ignore spaces    "
#2	echo "	diff -w now inline    "  
OK: 2 of 2 tests passed
$
```

## Option --prompt

```
$ ./clitest test/option-prompt.sh; echo $?
clitest: Error: no test found in input file: test/option-prompt.sh
2
$ ./clitest --prompt 'prompt$ ' test/option-prompt.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
OK: 3 of 3 tests passed
$ ./clitest --prompt '♥ ' test/option-prompt-unicode.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
OK: 3 of 3 tests passed
$
```

## Option --inline-prefix

```
$ ./clitest test/option-inline-prefix.sh
#1	echo "1 space" #==> 1 space
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "1 space" #==> 1 space
@@ -0,0 +1 @@
+1 space
--------------------------------------------------------------------------------
#2	echo "8 spaces"        #==> 8 spaces
--------------------------------------------------------------------------------
[FAILED #2, line 4] echo "8 spaces"        #==> 8 spaces
@@ -0,0 +1 @@
+8 spaces
--------------------------------------------------------------------------------
#3	echo "2 tabs"		#==> 2 tabs
--------------------------------------------------------------------------------
[FAILED #3, line 5] echo "2 tabs"		#==> 2 tabs
@@ -0,0 +1 @@
+2 tabs
--------------------------------------------------------------------------------

FAIL: 3 of 3 tests failed
$ ./clitest --inline-prefix '#==>' test/option-inline-prefix.sh
#1	echo "1 space" 
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "1 space" 
@@ -1 +1 @@
- 1 space
+1 space
--------------------------------------------------------------------------------
#2	echo "8 spaces"        
--------------------------------------------------------------------------------
[FAILED #2, line 4] echo "8 spaces"        
@@ -1 +1 @@
- 8 spaces
+8 spaces
--------------------------------------------------------------------------------
#3	echo "2 tabs"		
--------------------------------------------------------------------------------
[FAILED #3, line 5] echo "2 tabs"		
@@ -1 +1 @@
- 2 tabs
+2 tabs
--------------------------------------------------------------------------------

FAIL: 3 of 3 tests failed
$ ./clitest --inline-prefix '#==> ' test/option-inline-prefix.sh
#1	echo "1 space" 
#2	echo "8 spaces"        
#3	echo "2 tabs"		
OK: 3 of 3 tests passed
$
```

## Option --prefix

```
$ ./clitest --prefix '    ' test/option-prefix.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./clitest --prefix 4 test/option-prefix.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./clitest --prefix '\t' test/option-prefix-tab.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./clitest --prefix tab test/option-prefix-tab.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$
```

## Option --prefix: glob gotchas

```
$ ./clitest --prefix '?' test/option-prefix-glob.sh
#1	echo 'prefix ?'	
#2	echo 'prefix ?'
OK: 2 of 2 tests passed
$ ./clitest --prefix '*' test/option-prefix-glob.sh
#1	echo 'prefix *'	
#2	echo 'prefix *'
OK: 2 of 2 tests passed
$ ./clitest --prefix '#' test/option-prefix-glob.sh
#1	echo 'prefix #'	
#2	echo 'prefix #'
OK: 2 of 2 tests passed
$ ./clitest --prefix '%' test/option-prefix-glob.sh
#1	echo 'prefix %'	
#2	echo 'prefix %'
OK: 2 of 2 tests passed
$ ./clitest --prefix '##' test/option-prefix-glob.sh
#1	echo 'prefix ##'	
#2	echo 'prefix ##'
OK: 2 of 2 tests passed
$ ./clitest --prefix '%%' test/option-prefix-glob.sh
#1	echo 'prefix %%'	
#2	echo 'prefix %%'
OK: 2 of 2 tests passed
$ ./clitest --prefix '#*' test/option-prefix-glob.sh
#1	echo 'prefix #*'	
#2	echo 'prefix #*'
OK: 2 of 2 tests passed
$ ./clitest --prefix '*#' test/option-prefix-glob.sh
#1	echo 'prefix *#'	
#2	echo 'prefix *#'
OK: 2 of 2 tests passed
$ ./clitest --prefix '%*' test/option-prefix-glob.sh
#1	echo 'prefix %*'	
#2	echo 'prefix %*'
OK: 2 of 2 tests passed
$ ./clitest --prefix '*%' test/option-prefix-glob.sh
#1	echo 'prefix *%'	
#2	echo 'prefix *%'
OK: 2 of 2 tests passed
$
```

## Option --prompt: glob gotchas (char + space)

```
$ ./clitest --prompt '? ' test/option-prompt-glob-space.sh
#1	echo 'prompt ? '	
#2	echo 'prompt ? '
OK: 2 of 2 tests passed
$ ./clitest --prompt '* ' test/option-prompt-glob-space.sh
#1	echo 'prompt * '	
#2	echo 'prompt * '
OK: 2 of 2 tests passed
$ ./clitest --prompt '# ' test/option-prompt-glob-space.sh
#1	echo 'prompt # '	
#2	echo 'prompt # '
OK: 2 of 2 tests passed
$ ./clitest --prompt '% ' test/option-prompt-glob-space.sh
#1	echo 'prompt % '	
#2	echo 'prompt % '
OK: 2 of 2 tests passed
$ ./clitest --prompt '## ' test/option-prompt-glob-space.sh
#1	echo 'prompt ## '	
#2	echo 'prompt ## '
OK: 2 of 2 tests passed
$ ./clitest --prompt '%% ' test/option-prompt-glob-space.sh
#1	echo 'prompt %% '	
#2	echo 'prompt %% '
OK: 2 of 2 tests passed
$ ./clitest --prompt '#* ' test/option-prompt-glob-space.sh
#1	echo 'prompt #* '	
#2	echo 'prompt #* '
OK: 2 of 2 tests passed
$ ./clitest --prompt '*# ' test/option-prompt-glob-space.sh
#1	echo 'prompt *# '	
#2	echo 'prompt *# '
OK: 2 of 2 tests passed
$ ./clitest --prompt '%* ' test/option-prompt-glob-space.sh
#1	echo 'prompt %* '	
#2	echo 'prompt %* '
OK: 2 of 2 tests passed
$ ./clitest --prompt '*% ' test/option-prompt-glob-space.sh
#1	echo 'prompt *% '	
#2	echo 'prompt *% '
OK: 2 of 2 tests passed
$
```

## Option --prompt: glob gotchas (chars only)

```
$ ./clitest --prompt '?' test/option-prompt-glob-1.sh
#1	echo 'prompt ?'	
#2	echo 'prompt ?'
OK: 2 of 2 tests passed
$ ./clitest --prompt '*' test/option-prompt-glob-1.sh
#1	echo 'prompt *'	
#2	echo 'prompt *'
OK: 2 of 2 tests passed
$ ./clitest --prompt '#' test/option-prompt-glob-1.sh
#1	echo 'prompt #'	
#2	echo 'prompt #'
OK: 2 of 2 tests passed
$ ./clitest --prompt '%' test/option-prompt-glob-1.sh
#1	echo 'prompt %'	
#2	echo 'prompt %'
OK: 2 of 2 tests passed
$ ./clitest --prompt '##' test/option-prompt-glob-2.sh
#1	echo 'prompt ##'	
#2	echo 'prompt ##'
OK: 2 of 2 tests passed
$ ./clitest --prompt '%%' test/option-prompt-glob-2.sh
#1	echo 'prompt %%'	
#2	echo 'prompt %%'
OK: 2 of 2 tests passed
$ ./clitest --prompt '#*' test/option-prompt-glob-2.sh
#1	echo 'prompt #*'	
#2	echo 'prompt #*'
OK: 2 of 2 tests passed
$ ./clitest --prompt '*#' test/option-prompt-glob-2.sh
#1	echo 'prompt *#'	
#2	echo 'prompt *#'
OK: 2 of 2 tests passed
$ ./clitest --prompt '%*' test/option-prompt-glob-2.sh
#1	echo 'prompt %*'	
#2	echo 'prompt %*'
OK: 2 of 2 tests passed
$ ./clitest --prompt '*%' test/option-prompt-glob-2.sh
#1	echo 'prompt *%'	
#2	echo 'prompt *%'
OK: 2 of 2 tests passed
$
```

## Options --pre-flight and --post-flight

```
$ ./clitest --pre-flight 'tt_test_number=99; tt_nr_total_tests=99' test/ok-1.sh
#100	echo ok
OK: 100 of 100 tests passed
$ ./clitest --post-flight 'tt_nr_total_fails=50' test/ok-50.sh | tail -1
FAIL: 50 of 50 tests failed
$ ./clitest --pre-flight 'false' test/ok-1.sh; echo $?
clitest: Error: pre-flight command failed with status=1: false
2
$ ./clitest --post-flight 'false' test/ok-1.sh; echo $?
#1	echo ok
clitest: Error: post-flight command failed with status=1: false
2
$
```

## Invalid option

```
$ ./clitest --quiet --foo test/ok-1.sh
clitest: Error: invalid option --foo
$ ./clitest --first --foo test/ok-1.sh
clitest: Error: invalid option --foo
$ ./clitest --foo test/ok-1.sh
clitest: Error: invalid option --foo
$ ./clitest --foo
clitest: Error: invalid option --foo
$ ./clitest -Z; echo $?
clitest: Error: invalid option -Z
2
$
```

## Options terminator -- 

```
$ ./clitest -t 99 -- --quiet
clitest: Error: cannot read input file: --quiet
$
```

## File - meaning STDIN

```
$ cat test/ok-1.sh | ./clitest -
#1	echo ok
OK: 1 of 1 test passed
$ cat test/ok-1.sh | ./clitest -- -; echo $?
#1	echo ok
OK: 1 of 1 test passed
0
$
```

## Read test file from /dev/stdin

```
$ cat test/ok-1.sh | ./clitest /dev/stdin
#1	echo ok
OK: 1 of 1 test passed
$
```

## Test file is a symlink

```
$ ln -s test/ok-1.sh testsymlink
$ ./clitest testsymlink
#1	echo ok
OK: 1 of 1 test passed
$ rm testsymlink
$
```

## Gotchas

Test exit code and STDOUT/STDERR at the same time

```
$ ./clitest notfound; echo $?
clitest: Error: cannot read input file: notfound
2
$ ./clitest test/exit-code-and-stdout.sh 
#1	echo "zero"; echo $?
#2	echo "two"; sh -c "exit 2"; echo $?
OK: 2 of 2 tests passed
$
```

STDIN and STDOUT

```
$ ./clitest test/stdout-stderr.sh
#1	echo "stdout"
#2	echo "stdout" 2> /dev/null
#3	echo "stderr" 1>&2
#4	echo "stdout" > /dev/null
#5	echo "stdout" 2> /dev/null 1>&2
#6	./clitest notfound
#7	./clitest notfound > /dev/null
#8	./clitest notfound 2>&1
#9	./clitest notfound 2> /dev/null
#10	./clitest notfound > /dev/null 2>&1
OK: 10 of 10 tests passed
$
```

STDIN Isolation

```
$ ./clitest --quiet test/stdin-isolation.sh ; echo $?
0
$
```

Temporary files and directories must be removed after execution

```
$ TMPDIR__TEST=$(mktemp -d)
$ TMPDIR="$TMPDIR__TEST" ./clitest --help >/dev/null 2>&1
$ find "$TMPDIR__TEST" -mindepth 1
$ echo '$ true' | TMPDIR="$TMPDIR__TEST" ./clitest --debug - >/dev/null 2>&1
$ find "$TMPDIR__TEST" -mindepth 1
$ unset TMPDIR__TEST
$
```
Multiple commands in one line

```
$ ./clitest test/multi-commands.sh
#1	echo 1; echo 2; echo 3; echo 4; echo 5
#2	(echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p
#3	(echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p  
OK: 3 of 3 tests passed
$
```

A `cd` command in one test should not affect the next

```
$ ./clitest test/cd.sh test/ok-2.sh
Testing file test/cd.sh
#1	cd
Testing file test/ok-2.sh
#2	echo ok
#3	echo ok  

     ok  fail  skip
      1     -     -    test/cd.sh
      2     -     -    test/ok-2.sh

OK: 3 of 3 tests passed
$
```

Syntax: End-of-file or empty prompt closes the previous command

```
$ ./clitest test/close-command.sh
#1	echo 1
#2	echo 2
#3	echo 3
OK: 3 of 3 tests passed
$
```

Windows files (CR+LF)

```
$ ./clitest test/windows.sh
#1	echo "a file with CRLF line ending"
#2	echo "inline output"  
#3	echo "inline regex"  
OK: 3 of 3 tests passed
$
```

Unicode chars

```
$ ./clitest test/special-chars.sh | tail -1
OK: 206 of 206 tests passed
$
```

Blanks (space, tab, newline) in the output

```
$ ./clitest test/blank-output.sh
#1	echo ' '
#2	echo '    '
#3	printf '\t\n'
#4	printf '\t\t\t\n'
#5	printf ' \t  \t\t   \n'
#6	printf '\n \n  \n   \n    \n\n'
#7	printf '\n\t\n\t\t\n\t\t\t\n\t\t\t\t\n\n'
#8	printf '\n'
#9	printf '\n\n'
#10	printf '\n\n\n\n'
OK: 10 of 10 tests passed
$
```

Files with no newline (`\n`) at the end

1. No empty prompt at the last line
2. Empty prompt at the last line
3. Inline output

```
$ ./clitest test/no-nl-file-1.sh
#1	printf '%s\n' 'a file with no \n at the last line'
OK: 1 of 1 test passed
$ ./clitest test/no-nl-file-2.sh
#1	printf '%s\n' 'another file with no \n at the last line'
OK: 1 of 1 test passed
$ ./clitest test/no-nl-file-3.sh
#1	printf '%s\n' 'oneliner, no \n'  
OK: 1 of 1 test passed
$
```

Commands whose output has no `\n`

```
$ ./clitest test/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
--------------------------------------------------------------------------------
[FAILED #2, line 6] printf 'fail'
@@ -1 +1 @@
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#3	printf 'ok\nok\nfail'
--------------------------------------------------------------------------------
[FAILED #3, line 8] printf 'ok\nok\nfail'
@@ -1,3 +1,3 @@
 ok
 ok
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#4	printf 'ok\n'    
#5	printf 'fail'    
--------------------------------------------------------------------------------
[FAILED #5, line 17] printf 'fail'    
@@ -1 +1 @@
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#6	printf 'ok'; echo   
#7	printf 'ok'         

FAIL: 3 of 7 tests failed
$
```

## And now, the colored output tests

> Note that the escape character (`\033`) is removed to have only printable ASCII characters in the output.

```
$ ./clitest --color yes --first test/fail-2.sh | tr -d '\033'
#1	echo ok
[31m--------------------------------------------------------------------------------[m
[31m[FAILED #1, line 1] echo ok[m
@@ -1 +1 @@
-fail
+ok
[31m--------------------------------------------------------------------------------[m
$
```
