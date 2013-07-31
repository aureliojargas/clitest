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

# Set a default terminal width of 80 columns (used by separator lines) 

$ COLUMNS=80
$

# Single file, OK

$ ./doctest.sh --no-color self-test/ok-1.sh
OK! The single test has passed.
$ ./doctest.sh --no-color self-test/ok-2.sh
OK! All 2 tests have passed.
$ ./doctest.sh --no-color self-test/ok-50.sh
YOU WIN! All 50 tests have passed.
$ ./doctest.sh --no-color self-test/ok-100.sh
YOU WIN! PERFECT! All 100 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/ok-2.sh
=======[1] echo ok
=======[2] echo ok  
OK! All 2 tests have passed.
$

# Multifile, all OK

$ ./doctest.sh --no-color self-test/ok-2.sh self-test/ok-2.sh
Testing file self-test/ok-2.sh
Testing file self-test/ok-2.sh

================================================================================
 2 ok           self-test/ok-2.sh
 2 ok           self-test/ok-2.sh
================================================================================

OK! All 4 tests have passed.
$ ./doctest.sh --no-color self-test/ok-[0-9]*.sh
Testing file self-test/ok-1.sh
Testing file self-test/ok-10.sh
Testing file self-test/ok-100.sh
Testing file self-test/ok-2.sh
Testing file self-test/ok-50.sh

================================================================================
 1 ok           self-test/ok-1.sh
10 ok           self-test/ok-10.sh
100 ok           self-test/ok-100.sh
 2 ok           self-test/ok-2.sh
50 ok           self-test/ok-50.sh
================================================================================

YOU WIN! PERFECT! All 163 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/ok-?.sh self-test/ok-10.sh
Testing file self-test/ok-1.sh
=======[1] echo ok
Testing file self-test/ok-2.sh
=======[2] echo ok
=======[3] echo ok  
Testing file self-test/ok-10.sh
=======[4] echo 1 
=======[5] echo 2 
=======[6] echo 3 
=======[7] echo 4 
=======[8] echo 5 
=======[9] echo 6 
=======[10] echo 7 
=======[11] echo 8 
=======[12] echo 9 
=======[13] echo 10 

================================================================================
 1 ok           self-test/ok-1.sh
 2 ok           self-test/ok-2.sh
10 ok           self-test/ok-10.sh
================================================================================

OK! All 13 tests have passed.
$

# Multifile, OK and error

$ ./doctest.sh --no-color self-test/{ok-2,error-2,exit-code,windows}.sh
Testing file self-test/ok-2.sh
Testing file self-test/error-2.sh
--------------------------------------------------------------------------------
#3 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#4 FAILED: echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file self-test/exit-code.sh
Testing file self-test/windows.sh

================================================================================
 2 ok           self-test/ok-2.sh
 0 ok,  2 fail  self-test/error-2.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
================================================================================

FAIL: 2 of 7 tests have failed.
$ ./doctest.sh --no-color --verbose self-test/{ok-2,error-2,exit-code,windows}.sh
Testing file self-test/ok-2.sh
=======[1] echo ok
=======[2] echo ok  
Testing file self-test/error-2.sh
=======[3] echo ok
--------------------------------------------------------------------------------
#3 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
=======[4] echo ok  
--------------------------------------------------------------------------------
#4 FAILED: echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file self-test/exit-code.sh
=======[5] echo "ok"            > /dev/null; echo $?
=======[6] cp XXnotfoundXX foo 2> /dev/null; echo $?
Testing file self-test/windows.sh
=======[7] echo "a file with CRLF line ending"

================================================================================
 2 ok           self-test/ok-2.sh
 0 ok,  2 fail  self-test/error-2.sh
 2 ok           self-test/exit-code.sh
 1 ok           self-test/windows.sh
================================================================================

FAIL: 2 of 7 tests have failed.
$

# Errors

$ ./doctest.sh --no-color self-test/error-1.sh
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: The single test has failed.
$ ./doctest.sh --no-color self-test/error-2.sh
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#2 FAILED: echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

COMPLETE FAIL! All 2 tests have failed.
$ ./doctest.sh --no-color self-test/error-50.sh | tail -1
EPIC FAIL! All 50 tests have failed.
$ ./doctest.sh --no-color -1 self-test/error-2.sh
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./doctest.sh --no-color --abort self-test/error-2.sh
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./doctest.sh --no-color --abort --verbose self-test/error-2.sh
=======[1] echo ok
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./doctest.sh --no-color --verbose self-test/error-2.sh
=======[1] echo ok
--------------------------------------------------------------------------------
#1 FAILED: echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
=======[2] echo ok  
--------------------------------------------------------------------------------
#2 FAILED: echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

COMPLETE FAIL! All 2 tests have failed.
$

# Inline output with #→

$ ./doctest.sh --no-color --verbose self-test/inline.sh
=======[1] echo 'one space' 
=======[2] echo 'one tab'	
=======[3] echo 'multi spaces'           
=======[4] echo 'multi tabs'				
=======[5] echo 'mixed'  	 		 	
=======[6] echo ' leading space' 
=======[7] echo '    leading spaces' 
=======[8] printf '\tleading tab\n' 
=======[9] printf '\t\tleading tabs\n' 
=======[10] echo 'trailing space ' 
=======[11] echo 'trailing spaces    ' 
=======[12] printf 'trailing tab\t\n' 
=======[13] printf 'trailing tabs\t\t\n' 
=======[14] echo ' ' 
=======[15] echo '    ' 
=======[16] printf '\t\n' 
=======[17] printf '\t\t\t\n' 
=======[18] printf ' \t  \t\t   \n' 
=======[19] echo "both inline and normal output"  
OK! All 19 tests have passed.
$

# Inline match modes

$ ./doctest.sh --no-color --list-run self-test/inline-match-text.sh
1	OK	echo 'abc'                    
2	OK	echo 'abc'                    
3	OK	echo '\t'                     
4	OK	echo '\n'                     
5	OK	echo '$PWD'                   
6	OK	echo '$(date)'                
7	OK	echo '$'                      
8	OK	echo '>'                      
9	OK	echo '?'                      
10	OK	echo '!'                      
11	OK	echo '*'                      
12	OK	echo '['                      
13	OK	echo '('                      
14	OK	echo                          
15	OK	echo "not inline output"      #→
16	OK	echo '123456789'              
17	OK	echo '1 3   7 9'              
18	OK	echo '    5    '              
19	OK	echo ' leading space'         
20	OK	echo '    leading spaces'     
21	OK	printf '\tleading tab\n'      
22	OK	printf '\t\tleading tabs\n'   
23	OK	echo 'trailing space '        
24	OK	echo 'trailing spaces    '    
25	OK	printf 'trailing tab\t\n'     
26	OK	printf 'trailing tabs\t\t\n'  
27	OK	echo ' '                      
28	FAIL	echo '   '                    
29	OK	printf '\t\n'                 
30	OK	printf '\t\t\t\n'             
31	OK	printf ' \t  \t\t   \n'       
32	OK	echo 'ok'                     
33	OK	printf 'ok\n'                 
34	FAIL	echo -n 'fail'                
35	FAIL	printf 'fail'                 
36	OK	echo -n 'ok'; echo            
37	OK	printf 'ok'; echo             
38	FAIL	echo 'fail'                   
39	FAIL	echo 'fail'                   
40	OK	echo ' ok'                    
41	OK	echo '--text'                 
42	OK	echo '--textual'              
43	OK	echo '--text is cool'         
$ ./doctest.sh --no-color --list-run self-test/inline-match-regex.sh
1	OK	echo 'abc123'                 
2	OK	echo 'abc123'                 
3	OK	echo 'abc123'                 
4	OK	echo 'abc123'                 
5	OK	echo 'abc123'                 
6	OK	echo 'abc123'                 
7	OK	echo 'abc123'                 
8	OK	echo 'abc123'                 
9	OK	echo 'abc 123'                
10	OK	echo ' '                      
11	OK	echo '    '                   
12	OK	printf '\t\n'                 
13	OK	printf '\t\t\t\n'             
14	OK	printf ' \t  \t\t   \n'       
15	OK	printf 'may\tfail'            
16	FAIL	printf 'may\tfail'            
17	OK	printf 'will\tmatch'          
18	FAIL	printf 'will\nfail'           
19	FAIL	printf 'will\nfail'           
20	OK	printf '1\n2\n3\n4\nok\n'     
21	OK	echo 'ok'                     
22	OK	echo -n 'ok'                  
23	OK	printf 'ok'                   
24	OK	printf 'ok\n'                 
25	FAIL	echo 'fail'                   
26	FAIL	echo 'fail'                   
27	OK	echo ' ok'                    
28	OK	echo '--regex'                
29	OK	echo '--regexpal'             
30	OK	echo '--regex is cool'        
$ ./doctest.sh --no-color --list-run self-test/inline-match-file.sh
1	OK	printf '$ echo ok\nok\n'      
2	OK	echo 'ok' > /tmp/foo.txt
3	OK	echo 'ok'                     
4	FAIL	echo 'fail'                   
5	FAIL	echo 'fail'                   
6	OK	echo '--file'                 
7	OK	echo '--filer'                
8	OK	echo '--file is cool'         
$ ./doctest.sh self-test/inline-match-regex-error-1.sh
doctest.sh: Error: missing inline output regex at line 1 of self-test/inline-match-regex-error-1.sh
$ ./doctest.sh self-test/inline-match-regex-error-2.sh
egrep: parentheses not balanced
doctest.sh: Error: egrep: check your inline regex at line 1 of self-test/inline-match-regex-error-2.sh
$ ./doctest.sh self-test/inline-match-file-error-1.sh
doctest.sh: Error: missing inline output file at line 1 of self-test/inline-match-file-error-1.sh
$ ./doctest.sh self-test/inline-match-file-error-2.sh
doctest.sh: Error: cannot read inline output file 'XXnotfoundXX', from line 1 of self-test/inline-match-file-error-2.sh
$ ./doctest.sh self-test/inline-match-file-error-3.sh
doctest.sh: Error: cannot read inline output file '/etc/', from line 1 of self-test/inline-match-file-error-3.sh
$

# Option --version

$ v="$(grep ^my_version= ./doctest.sh | cut -d = -f 2 | tr -d \')"
$ ./doctest.sh -V | fgrep -x "doctest.sh $v" > /dev/null; echo $?
0
$ ./doctest.sh --version | fgrep -x "doctest.sh $v" > /dev/null; echo $?
0
$

# Option --help

$ ./doctest.sh | sed -n '1p; $p'
Usage: doctest.sh [OPTIONS] <FILES>
  -V, --version               Show program version and exit
$ ./doctest.sh -h | sed -n '1p; $p'
Usage: doctest.sh [OPTIONS] <FILES>
  -V, --version               Show program version and exit
$ ./doctest.sh --help | sed -n '1p; $p'
Usage: doctest.sh [OPTIONS] <FILES>
  -V, --version               Show program version and exit
$

# Option --quiet and exit code

$ ./doctest.sh -q self-test/ok-2.sh; echo $?
0
$ ./doctest.sh --quiet self-test/ok-2.sh; echo $?
0
$ ./doctest.sh --quiet self-test/ok-2.sh self-test/ok-2.sh; echo $?
0
$ ./doctest.sh --quiet self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet self-test/error-2.sh self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet self-test/ok-2.sh self-test/error-2.sh; echo $?
1
$ ./doctest.sh --quiet --verbose self-test/ok-2.sh
$ ./doctest.sh --quiet --verbose self-test/error-2.sh
$ ./doctest.sh --quiet --verbose self-test/ok-2.sh self-test/ok-2.sh
$ ./doctest.sh --quiet --verbose self-test/ok-2.sh self-test/error-2.sh
$ ./doctest.sh --quiet --debug self-test/ok-2.sh
$ ./doctest.sh --quiet --debug self-test/error-2.sh
$ ./doctest.sh --quiet --debug self-test/ok-2.sh self-test/ok-2.sh
$ ./doctest.sh --quiet --debug self-test/ok-2.sh self-test/error-2.sh
$

# Option --list

$ ./doctest.sh -l self-test/no-nl-command.sh; echo $?
1	echo 'ok'
2	printf 'ok\n'
3	echo -n 'error'
4	printf 'error'
5	printf 'ok\nok\nerror'
6	echo 'ok'        
7	printf 'ok\n'    
8	echo -n 'error'  
9	printf 'error'   
10	echo -n 'ok'; echo  
11	printf 'ok'; echo   
0
$ ./doctest.sh --list self-test/no-nl-command.sh
1	echo 'ok'
2	printf 'ok\n'
3	echo -n 'error'
4	printf 'error'
5	printf 'ok\nok\nerror'
6	echo 'ok'        
7	printf 'ok\n'    
8	echo -n 'error'  
9	printf 'error'   
10	echo -n 'ok'; echo  
11	printf 'ok'; echo   
$ ./doctest.sh --list self-test/no-nl-command.sh self-test/ok-1.sh; echo $?
---------------------------------------- self-test/no-nl-command.sh
1	echo 'ok'
2	printf 'ok\n'
3	echo -n 'error'
4	printf 'error'
5	printf 'ok\nok\nerror'
6	echo 'ok'        
7	printf 'ok\n'    
8	echo -n 'error'  
9	printf 'error'   
10	echo -n 'ok'; echo  
11	printf 'ok'; echo   
---------------------------------------- self-test/ok-1.sh
12	echo ok
0
$

# Option --list-run

$ ./doctest.sh --list-run self-test/no-nl-command.sh; echo $?
[32m1	echo 'ok'[m
[32m2	printf 'ok\n'[m
[31m3	echo -n 'error'[m
[31m4	printf 'error'[m
[31m5	printf 'ok\nok\nerror'[m
[32m6	echo 'ok'        [m
[32m7	printf 'ok\n'    [m
[31m8	echo -n 'error'  [m
[31m9	printf 'error'   [m
[32m10	echo -n 'ok'; echo  [m
[32m11	printf 'ok'; echo   [m
1
$ ./doctest.sh --list-run --no-color self-test/no-nl-command.sh; echo $?
1	OK	echo 'ok'
2	OK	printf 'ok\n'
3	FAIL	echo -n 'error'
4	FAIL	printf 'error'
5	FAIL	printf 'ok\nok\nerror'
6	OK	echo 'ok'        
7	OK	printf 'ok\n'    
8	FAIL	echo -n 'error'  
9	FAIL	printf 'error'   
10	OK	echo -n 'ok'; echo  
11	OK	printf 'ok'; echo   
1
$ ./doctest.sh -L --no-color self-test/no-nl-command.sh
1	OK	echo 'ok'
2	OK	printf 'ok\n'
3	FAIL	echo -n 'error'
4	FAIL	printf 'error'
5	FAIL	printf 'ok\nok\nerror'
6	OK	echo 'ok'        
7	OK	printf 'ok\n'    
8	FAIL	echo -n 'error'  
9	FAIL	printf 'error'   
10	OK	echo -n 'ok'; echo  
11	OK	printf 'ok'; echo   
$ ./doctest.sh -L --no-color self-test/no-nl-command.sh self-test/ok-1.sh; echo $?
---------------------------------------- self-test/no-nl-command.sh
1	OK	echo 'ok'
2	OK	printf 'ok\n'
3	FAIL	echo -n 'error'
4	FAIL	printf 'error'
5	FAIL	printf 'ok\nok\nerror'
6	OK	echo 'ok'        
7	OK	printf 'ok\n'    
8	FAIL	echo -n 'error'  
9	FAIL	printf 'error'   
10	OK	echo -n 'ok'; echo  
11	OK	printf 'ok'; echo   
---------------------------------------- self-test/ok-1.sh
12	OK	echo ok
1
$ ./doctest.sh -L --no-color self-test/ok-1.sh; echo $?
1	OK	echo ok
0
$

# Option -n, --number

$ ./doctest.sh -n - self-test/ok-2.sh
doctest.sh: Error: invalid argument for -n or --number: -
$ ./doctest.sh -n -1 self-test/ok-2.sh
doctest.sh: Error: invalid argument for -n or --number: -1
$ ./doctest.sh -n 1- self-test/ok-2.sh
doctest.sh: Error: invalid argument for -n or --number: 1-
$ ./doctest.sh -n 1--2 self-test/ok-2.sh
doctest.sh: Error: invalid argument for -n or --number: 1--2
$ ./doctest.sh -n 1-2-3 self-test/ok-2.sh
doctest.sh: Error: invalid argument for -n or --number: 1-2-3
$ ./doctest.sh -n 99 self-test/ok-2.sh
doctest.sh: Error: no test found for the specified number or range '99'
$ ./doctest.sh --no-color -n '' self-test/ok-2.sh
OK! All 2 tests have passed.
$ ./doctest.sh --no-color -n 0 self-test/ok-2.sh
OK! All 2 tests have passed.
$ ./doctest.sh --no-color -n ,,,0,0-0,,, self-test/ok-2.sh
OK! All 2 tests have passed.
$ ./doctest.sh --no-color --verbose -n 1 self-test/ok-10.sh
=======[1] echo 1 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose --number 1 self-test/ok-10.sh
=======[1] echo 1 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose -n 0-1,1-0 self-test/ok-10.sh
=======[1] echo 1 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose -n 1-1 self-test/ok-10.sh
=======[1] echo 1 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose -n 1,1,1,0,1 self-test/ok-10.sh
=======[1] echo 1 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose -n 10-20 self-test/ok-10.sh
=======[10] echo 10 
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose -n 3,2,1 self-test/ok-10.sh
=======[1] echo 1 
=======[2] echo 2 
=======[3] echo 3 
OK! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose -n 3-1 self-test/ok-10.sh
=======[1] echo 1 
=======[2] echo 2 
=======[3] echo 3 
OK! All 3 tests have passed.
$ ./doctest.sh --no-color -n 1,5,13 self-test/ok-{1,2,10}.sh
Testing file self-test/ok-1.sh
Testing file self-test/ok-2.sh
Testing file self-test/ok-10.sh

================================================================================
 1 ok           self-test/ok-1.sh
 0 ok           self-test/ok-2.sh
 2 ok           self-test/ok-10.sh
================================================================================

OK! All 3 tests have passed.
$ ./doctest.sh --no-color -n 1,5 self-test/ok-[12].sh self-test/error-2.sh
Testing file self-test/ok-1.sh
Testing file self-test/ok-2.sh
Testing file self-test/error-2.sh
--------------------------------------------------------------------------------
#5 FAILED: echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

================================================================================
 1 ok           self-test/ok-1.sh
 0 ok           self-test/ok-2.sh
 0 ok,  1 fail  self-test/error-2.sh
================================================================================

FAIL: 1 of 2 tests have failed.
$ ./doctest.sh --no-color -n 1 self-test/ok-[12].sh self-test/error-2.sh
Testing file self-test/ok-1.sh
Testing file self-test/ok-2.sh
Testing file self-test/error-2.sh

================================================================================
 1 ok           self-test/ok-1.sh
 0 ok           self-test/ok-2.sh
 0 ok           self-test/error-2.sh
================================================================================

OK! The single test has passed.
$

# Option --number with --list and --list-run

$ ./doctest.sh --no-color --list -n 3,5-7 self-test/ok-10.sh
3	echo 3 
5	echo 5 
6	echo 6 
7	echo 7 
$ ./doctest.sh --no-color --list-run -n 3,5-7 self-test/ok-10.sh
3	OK	echo 3 
5	OK	echo 5 
6	OK	echo 6 
7	OK	echo 7 
$ ./doctest.sh --no-color --list -n 1,3,5-7 self-test/{ok-1,error-2,ok-10}.sh
---------------------------------------- self-test/ok-1.sh
1	echo ok
---------------------------------------- self-test/error-2.sh
3	echo ok  
---------------------------------------- self-test/ok-10.sh
5	echo 2 
6	echo 3 
7	echo 4 
$ ./doctest.sh --no-color --list-run -n 1,3,5-7 self-test/{ok-1,error-2,ok-10}.sh
---------------------------------------- self-test/ok-1.sh
1	OK	echo ok
---------------------------------------- self-test/error-2.sh
3	FAIL	echo ok  
---------------------------------------- self-test/ok-10.sh
5	OK	echo 2 
6	OK	echo 3 
7	OK	echo 4 
$

# Option --diff-options

$ ./doctest.sh --no-color self-test/option-diff-options.sh
--------------------------------------------------------------------------------
#1 FAILED: echo "	diff -w to ignore spaces    "
@@ -1 +1 @@
-diff -w    to ignore     spaces
+	diff -w to ignore spaces    
--------------------------------------------------------------------------------

FAIL: The single test has failed.
$ ./doctest.sh --no-color --diff-options '-u -w' self-test/option-diff-options.sh
OK! The single test has passed.
$

# Option --prompt

$ ./doctest.sh --no-color --verbose self-test/option-prompt.sh
doctest.sh: Error: no test found in input file: self-test/option-prompt.sh
$ ./doctest.sh --no-color --verbose --prompt 'prompt$ ' self-test/option-prompt.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
OK! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose --prompt '♥ ' self-test/option-prompt-unicode.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
OK! All 3 tests have passed.
$

# Option --inline-prefix

$ ./doctest.sh --no-color self-test/option-inline-prefix.sh
--------------------------------------------------------------------------------
#1 FAILED: echo "1 space" #==> 1 space
@@ -0,0 +1 @@
+1 space
--------------------------------------------------------------------------------
#2 FAILED: echo "8 spaces"        #==> 8 spaces
@@ -0,0 +1 @@
+8 spaces
--------------------------------------------------------------------------------
#3 FAILED: echo "2 tabs"		#==> 2 tabs
@@ -0,0 +1 @@
+2 tabs
--------------------------------------------------------------------------------

COMPLETE FAIL! All 3 tests have failed.
$ ./doctest.sh --no-color --inline-prefix '#==>' self-test/option-inline-prefix.sh
--------------------------------------------------------------------------------
#1 FAILED: echo "1 space" 
@@ -1 +1 @@
- 1 space
+1 space
--------------------------------------------------------------------------------
#2 FAILED: echo "8 spaces"        
@@ -1 +1 @@
- 8 spaces
+8 spaces
--------------------------------------------------------------------------------
#3 FAILED: echo "2 tabs"		
@@ -1 +1 @@
- 2 tabs
+2 tabs
--------------------------------------------------------------------------------

COMPLETE FAIL! All 3 tests have failed.
$ ./doctest.sh --no-color --inline-prefix '#==> ' self-test/option-inline-prefix.sh
OK! All 3 tests have passed.
$

# Option --prefix

$ ./doctest.sh --no-color --verbose --prefix '    ' self-test/option-prefix.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
=======[4] echo "4"
=======[5] echo "5"  
=======[6] echo; echo "6"; echo; echo "7"
OK! All 6 tests have passed.
$ ./doctest.sh --no-color --verbose --prefix 4 self-test/option-prefix.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
=======[4] echo "4"
=======[5] echo "5"  
=======[6] echo; echo "6"; echo; echo "7"
OK! All 6 tests have passed.
$ ./doctest.sh --no-color --verbose --prefix '\t' self-test/option-prefix-tab.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
=======[4] echo "4"
=======[5] echo "5"  
=======[6] echo; echo "6"; echo; echo "7"
OK! All 6 tests have passed.
$ ./doctest.sh --no-color --verbose --prefix tab self-test/option-prefix-tab.sh
=======[1] echo "1"  
=======[2] echo "2"
=======[3] echo "3"
=======[4] echo "4"
=======[5] echo "5"  
=======[6] echo; echo "6"; echo; echo "7"
OK! All 6 tests have passed.
$

# I/O, file reading

$ ./doctest.sh XxnotfoundXX.sh
doctest.sh: Error: cannot read input file: XxnotfoundXX.sh
$ ./doctest.sh self-test
doctest.sh: Error: cannot read input file: self-test
$ ./doctest.sh self-test/
doctest.sh: Error: cannot read input file: self-test/
$

# No test found (message and exit code)

$ ./doctest.sh self-test/no-test-found.sh; echo $?
doctest.sh: Error: no test found in input file: self-test/no-test-found.sh
2
$ ./doctest.sh self-test/empty-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-file.sh
$ ./doctest.sh self-test/empty-prompt-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-prompt-file.sh
$ ./doctest.sh self-test/empty-prompts-file.sh
doctest.sh: Error: no test found in input file: self-test/empty-prompts-file.sh
$

# Gotchas

$ ./doctest.sh --no-color self-test/exit-code.sh
OK! All 2 tests have passed.
$ ./doctest.sh --no-color self-test/blank-output.sh
OK! All 10 tests have passed.
$ ./doctest.sh --no-color self-test/special-chars.sh
YOU WIN! PERFECT! All 206 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/windows.sh
=======[1] echo "a file with CRLF line ending"
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose self-test/close-command.sh
=======[1] echo 1
=======[2] echo 2
=======[3] echo 3
OK! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/multi-commands.sh
=======[1] echo 1; echo 2; echo 3; echo 4; echo 5
=======[2] (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p
=======[3] (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p  
OK! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/stdout-stderr.sh
=======[1] echo "stdout"
=======[2] echo "stdout" 2> /dev/null
=======[3] echo "stderr" 1>&2
=======[4] echo "stdout" > /dev/null
=======[5] echo "stdout" 2> /dev/null 1>&2
=======[6] cp XXnotfoundXX foo
=======[7] cp XXnotfoundXX foo > /dev/null
=======[8] cp XXnotfoundXX foo 2>&1
=======[9] cp XXnotfoundXX foo 2> /dev/null
=======[10] cp XXnotfoundXX foo > /dev/null 2>&1
OK! All 10 tests have passed.
$ ./doctest.sh --no-color self-test/cd.sh self-test/ok-2.sh
Testing file self-test/cd.sh
Testing file self-test/ok-2.sh

================================================================================
 1 ok           self-test/cd.sh
 2 ok           self-test/ok-2.sh
================================================================================

OK! All 3 tests have passed.
$ ./doctest.sh --no-color --verbose self-test/no-nl-file.sh
=======[1] echo "a file with no \n at the last line"
OK! The single test has passed.
$ ./doctest.sh --no-color --verbose self-test/no-nl-command.sh
=======[1] echo 'ok'
=======[2] printf 'ok\n'
=======[3] echo -n 'error'
--------------------------------------------------------------------------------
#3 FAILED: echo -n 'error'
@@ -1 +1 @@
-error
+error
\ No newline at end of file
--------------------------------------------------------------------------------
=======[4] printf 'error'
--------------------------------------------------------------------------------
#4 FAILED: printf 'error'
@@ -1 +1 @@
-error
+error
\ No newline at end of file
--------------------------------------------------------------------------------
=======[5] printf 'ok\nok\nerror'
--------------------------------------------------------------------------------
#5 FAILED: printf 'ok\nok\nerror'
@@ -1,3 +1,3 @@
 ok
 ok
-error
+error
\ No newline at end of file
--------------------------------------------------------------------------------
=======[6] echo 'ok'        
=======[7] printf 'ok\n'    
=======[8] echo -n 'error'  
--------------------------------------------------------------------------------
#8 FAILED: echo -n 'error'  
@@ -1 +1 @@
-error
+error
\ No newline at end of file
--------------------------------------------------------------------------------
=======[9] printf 'error'   
--------------------------------------------------------------------------------
#9 FAILED: printf 'error'   
@@ -1 +1 @@
-error
+error
\ No newline at end of file
--------------------------------------------------------------------------------
=======[10] echo -n 'ok'; echo  
=======[11] printf 'ok'; echo   

FAIL: 5 of 11 tests have failed.
$

# And now, the colored output tests

$ ./doctest.sh --abort self-test/error-2.sh
[31m--------------------------------------------------------------------------------[m
[31m#1 FAILED: echo ok[m
@@ -1 +1 @@
-fail
+ok
[31m--------------------------------------------------------------------------------[m
