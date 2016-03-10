# Inline matching method: --perl
# Matches a Perl-style regular expression in the command output
# You can also use the friendlier alias: --regex
#
# In fact, it's a real Perl match: perl -0777 -ne "exit(!m'regex')"
# If Perl matched, we have a successful test.
# All the test output lines are matched as a single string.
# No modifiers are used by default, inform yours if needed: (?ims)
# You don't need to escape the ' delimiter, the script will do it for you.
# Just write your regex not worrying about delimiters.


# Use anchors ^ and $ to match the full output text

$ echo 'abc123'                 #=> --perl ^abc123$
$ echo 'abc123'                 #=> --perl ^abc.*3$
$ echo 'abc123'                 #=> --perl ^abc[0-9]+$

# Omit one or both anchors to make a parcial match

$ echo 'abc123'                 #=> --perl ^abc
$ echo 'abc123'                 #=> --perl 123$
$ echo 'abc123'                 #=> --perl [0-9]+$
$ echo 'abc123'                 #=> --perl bc
$ echo 'abc123'                 #=> --perl .

# Blanks are preserved, no escaping or quoting needed

$ echo 'abc 123'                #=> --perl ^abc [0-9]+$

# Blank output can also be matched

$ echo ' '                      #=> --perl ^ $
$ echo '    '                   #=> --perl ^    $
$ printf '\t\n'                 #=> --perl ^	$
$ printf '\t\t\t\n'             #=> --perl ^			$
$ printf ' \t  \t\t   \n'       #=> --perl ^ 	  		   $

# You don't need to escape any delimiters, escapes are handled by the script

$ echo '01/01/2013'             #=> --perl ^../../....$
$ echo "won't fail"             #=> --perl ^won't \w+$

# To match a tab, you can use \t or a literal tab

$ printf 'will\tmatch'          #=> --perl ^will\tmatch$
$ printf 'will\tmatch'          #=> --perl ^will[\t]match$
$ printf 'will\tmatch'          #=> --perl ^will	match$

# You need to inform the (?i) modifier to match ignoring case

$ printf 'will\nfail'           #=> --perl ^WILL
$ printf 'will\nmatch'          #=> --perl (?i)^WILL

# You need to inform the (?s) modifier for the dot to match \n

$ printf 'will\nfail'           #=> --perl ^will.fail$
$ printf 'will\nmatch'          #=> --perl (?s)^will.match$

# You need to inform the (?m) modifier for ^ and $ to match inner lines

$ printf 'will\nfail'           #=> --perl ^fail
$ printf 'will\nmatch'          #=> --perl (?m)^match

# Perl ignores the last \n, in both the text and the regex

$ printf 'ok'                   #=> --perl ^ok$
$ printf 'ok\n'                 #=> --perl ^ok$
$ printf '1\n2\n3\n'            #=> --perl ^1\n2\n3\n$
$ printf '1\n2\n3\n'            #=> --perl ^1\n2\n3$

# Syntax: Must be exactly one space before and after --perl

$ echo 'fail'                   #=>   --perl fail with 2 spaces
$ echo 'fail'                   #=> --perl	fail with tab

# Syntax: The extra space after '--perl ' is already part of the regex

$ echo ' ok'                    #=> --perl  ok

# Syntax: The space after --perl is required.
# When missing, the '--perl' is considered a normal text.

$ echo '--perl'                 #=> --perl

# Syntax: Make sure we won't catch partial matches.

$ echo '--perlism'              #=> --perlism

# Syntax: To insert a literal text that begins with '--perl '
#         just prefix it with --text.

$ echo '--perl is cool'         #=> --text --perl is cool

# Syntax: Empty inline output contents are considered an error
# Note: Tested in a separate file: inline-match-perl-error-1.sh
#
# $ echo 'no contents'          #=> --perl 
