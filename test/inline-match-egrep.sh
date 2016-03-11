# Inline matching method: --egrep
# Matches a egrep-style regular expression in the command output
#
# In fact, it's a real egrep match: eval $command | egrep 'regex'
# If egrep matched, we have a successful test. That means that in
# a multiline result, even if just a single line matches the regex,
# the test is considered OK.
#
# Test your regexes with egrep at the command line before adding
# tests using them.

# See man re_format in your system
# http://www.freebsd.org/cgi/man.cgi?query=re_format&sektion=7

# Use anchors ^ and $ to match the full output text

$ echo 'abc123'                 #=> --egrep ^abc123$
$ echo 'abc123'                 #=> --egrep ^abc.*3$
$ echo 'abc123'                 #=> --egrep ^abc[0-9]+$

# Omit one or both anchors to make a parcial match

$ echo 'abc123'                 #=> --egrep ^abc
$ echo 'abc123'                 #=> --egrep 123$
$ echo 'abc123'                 #=> --egrep [0-9]+$
$ echo 'abc123'                 #=> --egrep bc
$ echo 'abc123'                 #=> --egrep .

# Blanks are preserved, no escaping or quoting needed

$ echo 'abc 123'                #=> --egrep ^abc [0-9]+$

# Blank output can also be matched

$ echo ' '                      #=> --egrep ^ $
$ echo '    '                   #=> --egrep ^    $
$ printf '\t\n'                 #=> --egrep ^	$
$ printf '\t\t\t\n'             #=> --egrep ^			$
$ printf ' \t  \t\t   \n'       #=> --egrep ^ 	  		   $

# In some systems, the special sequence \t is expanded to a tab in
# egrep regexes. You'll need to test in your system if that's the
# case. I recommend using a literal tab to avoid problems.

$ printf 'may\tfail'            #=> --egrep ^may\tfail$
$ printf 'may\tfail'            #=> --egrep ^may[\t]fail$
$ printf 'will\tmatch'          #=> --egrep ^will	match$

# Since it's an egrep test, regexes are not multiline.
# You can only match a single line.
# These tests will fail:

$ printf 'will\nfail'           #=> --egrep will.*fail
$ printf 'will\nfail'           #=> --egrep will\nfail

# If one line of a multiline results matches, the test is OK

$ printf '1\n2\n3\n4\nok\n'     #=> --egrep ok

# As egrep is used for the test and it ignores the line break,
# you can match both full (with \n) and partial (without \n).

$ printf 'ok'                   #=> --egrep ok
$ printf 'ok\n'                 #=> --egrep ok

# Syntax: Must be exactly one space before and after --egrep

$ echo 'fail'                   #=>   --egrep fail with 2 spaces
$ echo 'fail'                   #=> --egrep	fail with tab

# Syntax: The extra space after '--egrep ' is already part of the regex

$ echo ' ok'                    #=> --egrep  ok

# Syntax: The space after --egrep is required.
# When missing, the '--egrep' is considered a normal text.

$ echo '--egrep'                #=> --egrep

# Syntax: Make sure we won't catch partial matches.

$ echo '--egreppal'             #=> --egreppal

# Syntax: To insert a literal text that begins with '--egrep '
#         just prefix it with --text.

$ echo '--egrep is cool'        #=> --text --egrep is cool

# Syntax: Empty inline output contents are considered an error
# Note: Tested in a separate file: inline-match-egrep-error-1.sh
#
# $ echo 'no contents'          #=> --egrep 
