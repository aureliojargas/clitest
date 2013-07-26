###
### This is the test file for the doctest.sh program.
### Yes, the program can test itself!
###
### This file runs all the files inside the self-test folder and
### checks the results. The command line options are also tested.
###
### Usage: ./doctest.sh self-test.sh
###

# Make sure we're on the same folder as doctest.sh, since all the
# file paths here are relative, not absolute.

$ cd "$(dirname "$0")"
$

# Single file, OK

$ ./doctest.sh --no-color self-test/ok.sh
YOU WIN! All 2 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/ok.sh
======= echo ok
======= echo ok  
YOU WIN! All 2 tests have passed.
$

# Multifile, all OK

$ ./doctest.sh --no-color self-test/ok.sh self-test/ok.sh
Testing file self-test/ok.sh
Testing file self-test/ok.sh

--------------------------------------------------
 2 ok           self-test/ok.sh
 2 ok           self-test/ok.sh
--------------------------------------------------

YOU WIN! All 4 tests have passed.
$ ./doctest.sh --no-color self-test/{ok,inline,exit-code,windows}.sh
Testing file self-test/ok.sh
Testing file self-test/inline.sh
Testing file self-test/exit-code.sh
Testing file self-test/windows.sh

--------------------------------------------------
 2 ok           self-test/ok.sh
18 ok           self-test/inline.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
--------------------------------------------------

YOU WIN! All 23 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/{ok,inline,exit-code,windows}.sh
Testing file self-test/ok.sh
======= echo ok
======= echo ok  
Testing file self-test/inline.sh
======= echo 'one space' 
======= echo 'one tab'	
======= echo 'multi spaces'           
======= echo 'multi tabs'				
======= echo 'mixed'  	 		 	
======= echo ' leading space' 
======= echo '    leading spaces' 
======= printf '\tleading tab\n' 
======= printf '\t\tleading tabs\n' 
======= echo 'trailing space ' 
======= echo 'trailing spaces    ' 
======= printf 'trailing tab\t\n' 
======= printf 'trailing tabs\t\t\n' 
======= echo ' ' 
======= echo '    ' 
======= printf '\t\n' 
======= printf '\t\t\t\n' 
======= printf ' \t  \t\t   \n' 
Testing file self-test/exit-code.sh
======= echo "ok"            > /dev/null; echo $?
======= cp XXnotfoundXX foo 2> /dev/null; echo $?
Testing file self-test/windows.sh
======= echo "a file with CRLF line ending"

--------------------------------------------------
 2 ok           self-test/ok.sh
18 ok           self-test/inline.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
--------------------------------------------------

YOU WIN! All 23 tests have passed.
$

# Multifile, OK and error

$ ./doctest.sh --no-color self-test/{ok,error-2,exit-code,windows}.sh
Testing file self-test/ok.sh
Testing file self-test/error-2.sh

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail

FAILED: echo fail  
@@ -1 +1 @@
-ok
+fail
Testing file self-test/exit-code.sh
Testing file self-test/windows.sh

--------------------------------------------------
 2 ok           self-test/ok.sh
 0 ok,  2 fail  self-test/error-2.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
--------------------------------------------------

FAIL: 2 of 7 tests have failed.
$ ./doctest.sh --no-color --verbose self-test/{ok,error-2,exit-code,windows}.sh
Testing file self-test/ok.sh
======= echo ok
======= echo ok  
Testing file self-test/error-2.sh
======= echo fail

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail
======= echo fail  

FAILED: echo fail  
@@ -1 +1 @@
-ok
+fail
Testing file self-test/exit-code.sh
======= echo "ok"            > /dev/null; echo $?
======= cp XXnotfoundXX foo 2> /dev/null; echo $?
Testing file self-test/windows.sh
======= echo "a file with CRLF line ending"

--------------------------------------------------
 2 ok           self-test/ok.sh
 0 ok,  2 fail  self-test/error-2.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
--------------------------------------------------

FAIL: 2 of 7 tests have failed.
$

# Errors

$ ./doctest.sh --no-color self-test/error-1.sh

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail

FAIL: The single test has failed.
$ ./doctest.sh --no-color self-test/error-2.sh

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail

FAILED: echo fail  
@@ -1 +1 @@
-ok
+fail

EPIC FAIL! All 2 tests have failed.
$ ./doctest.sh --no-color --abort self-test/error-2.sh

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail
$ ./doctest.sh --no-color --abort --verbose self-test/error-2.sh
======= echo fail

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail
$ ./doctest.sh --no-color --verbose self-test/error-2.sh
======= echo fail

FAILED: echo fail
@@ -1 +1 @@
-ok
+fail
======= echo fail  

FAILED: echo fail  
@@ -1 +1 @@
-ok
+fail

EPIC FAIL! All 2 tests have failed.
$

# Inline output with #→

$ ./doctest.sh --no-color --verbose self-test/inline.sh
======= echo 'one space' 
======= echo 'one tab'	
======= echo 'multi spaces'           
======= echo 'multi tabs'				
======= echo 'mixed'  	 		 	
======= echo ' leading space' 
======= echo '    leading spaces' 
======= printf '\tleading tab\n' 
======= printf '\t\tleading tabs\n' 
======= echo 'trailing space ' 
======= echo 'trailing spaces    ' 
======= printf 'trailing tab\t\n' 
======= printf 'trailing tabs\t\t\n' 
======= echo ' ' 
======= echo '    ' 
======= printf '\t\n' 
======= printf '\t\t\t\n' 
======= printf ' \t  \t\t   \n' 
YOU WIN! All 18 tests have passed.
$

# Quiet output with --quiet and exit code

$ ./doctest.sh --quiet self-test/ok.sh; echo $?
0
$ ./doctest.sh --quiet self-test/ok.sh self-test/ok.sh; echo $?
0
$ ./doctest.sh --quiet self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet self-test/error-2.sh self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet self-test/ok.sh self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet --verbose self-test/ok.sh
$ ./doctest.sh --quiet --verbose self-test/error-2.sh
$ ./doctest.sh --quiet --verbose self-test/ok.sh self-test/ok.sh
$ ./doctest.sh --quiet --verbose self-test/ok.sh self-test/error-2.sh
$ ./doctest.sh --quiet --debug self-test/ok.sh
$ ./doctest.sh --quiet --debug self-test/error-2.sh
$ ./doctest.sh --quiet --debug self-test/ok.sh self-test/ok.sh
$ ./doctest.sh --quiet --debug self-test/ok.sh self-test/error-2.sh
$

# Option --diff-options

$ ./doctest.sh --no-color self-test/option-diff-options.sh

FAILED: echo "	diff -w to ignore spaces    "
@@ -1 +1 @@
-diff -w    to ignore     spaces
+	diff -w to ignore spaces    

FAIL: The single test has failed.
$ ./doctest.sh --no-color --diff-options '-u -w' self-test/option-diff-options.sh
YOU WIN! The single test has passed.
$

# Option --prompt

$ ./doctest.sh --no-color --verbose self-test/option-prompt.sh
doctest.sh: Error: no test found in input file: self-test/option-prompt.sh
$ ./doctest.sh --no-color --verbose --prompt 'prompt$ ' self-test/option-prompt.sh
======= echo "1"  
======= echo "2"
======= echo "3"
YOU WIN! All 3 tests have passed.
$

# Option --inline-mark

$ ./doctest.sh --no-color self-test/option-inline-mark.sh

FAILED: echo "1 space" #==> 1 space
@@ -0,0 +1 @@
+1 space

FAILED: echo "8 spaces"        #==> 8 spaces
@@ -0,0 +1 @@
+8 spaces

FAILED: echo "2 tabs"		#==> 2 tabs
@@ -0,0 +1 @@
+2 tabs

EPIC FAIL! All 3 tests have failed.
$ ./doctest.sh --no-color --inline-mark '#==>' self-test/option-inline-mark.sh

FAILED: echo "1 space" 
@@ -1 +1 @@
- 1 space
+1 space

FAILED: echo "8 spaces"        
@@ -1 +1 @@
- 8 spaces
+8 spaces

FAILED: echo "2 tabs"		
@@ -1 +1 @@
- 2 tabs
+2 tabs

EPIC FAIL! All 3 tests have failed.
$ ./doctest.sh --no-color --inline-mark '#==> ' self-test/option-inline-mark.sh
YOU WIN! All 3 tests have passed.
$

# I/O, file reading

$ ./doctest.sh XxnotfoundXX.sh
doctest.sh: Error: cannot read input file: XxnotfoundXX.sh
$ ./doctest.sh self-test
doctest.sh: Error: cannot read input file: self-test
$ ./doctest.sh self-test/
doctest.sh: Error: cannot read input file: self-test/
$

# No test found (message and exit code 1)
$ ./doctest.sh self-test/no-test-found.sh; echo $?
doctest.sh: Error: no test found in input file: self-test/no-test-found.sh
1
$ ./doctest.sh self-test/empty-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-file.sh
$ ./doctest.sh self-test/empty-prompt-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-prompt-file.sh
$ ./doctest.sh self-test/empty-prompts-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-prompts-file.sh
$

# Gotchas

$ ./doctest.sh --no-color self-test/exit-code.sh
YOU WIN! All 2 tests have passed.
$ ./doctest.sh --no-color self-test/blank-output.sh
YOU WIN! All 10 tests have passed.
$ ./doctest.sh --no-color self-test/special-chars.sh
YOU WIN! PERFECT! All 206 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/windows.sh
======= echo "a file with CRLF line ending"
YOU WIN! The single test has passed.
$ ./doctest.sh --no-color --verbose self-test/close-command.sh
======= echo 1
======= echo 2
======= echo 3
YOU WIN! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/multi-commands.sh
======= echo 1; echo 2; echo 3; echo 4; echo 5
======= (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p
======= (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p  
YOU WIN! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/stdout-stderr.sh
======= echo "stdout"
======= echo "stdout" 2> /dev/null
======= echo "stderr" 1>&2
======= echo "stdout" > /dev/null
======= echo "stdout" 2> /dev/null 1>&2
======= cp XXnotfoundXX foo
======= cp XXnotfoundXX foo > /dev/null
======= cp XXnotfoundXX foo 2>&1
======= cp XXnotfoundXX foo 2> /dev/null
======= cp XXnotfoundXX foo > /dev/null 2>&1
YOU WIN! All 10 tests have passed.
$ ./doctest.sh --no-color self-test/cd.sh self-test/ok.sh
Testing file self-test/cd.sh
Testing file self-test/ok.sh

--------------------------------------------------
 1 ok           self-test/cd.sh
 2 ok           self-test/ok.sh
--------------------------------------------------

YOU WIN! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/no-nl-file.sh
======= echo "a file with no \n at the last line"
YOU WIN! The single test has passed.
$ ./doctest.sh --no-color --verbose self-test/no-nl-command.sh
======= echo 'ok'
======= printf 'ok\n'
======= echo -n 'error'

FAILED: echo -n 'error'
@@ -1 +1 @@
-error
+error
\ No newline at end of file
======= printf 'error'

FAILED: printf 'error'
@@ -1 +1 @@
-error
+error
\ No newline at end of file
======= printf 'ok\nok\nerror'

FAILED: printf 'ok\nok\nerror'
@@ -1,3 +1,3 @@
 ok
 ok
-error
+error
\ No newline at end of file
======= echo 'ok'        
======= printf 'ok\n'    
======= echo -n 'error'  

FAILED: echo -n 'error'  
@@ -1 +1 @@
-error
+error
\ No newline at end of file
======= printf 'error'   

FAILED: printf 'error'   
@@ -1 +1 @@
-error
+error
\ No newline at end of file

FAIL: 5 of 9 tests have failed.
$

# And now, the colored output tests

$ ./doctest.sh --abort self-test/error-2.sh

[31mFAILED: echo fail[m
@@ -1 +1 @@
-ok
+fail
