# Inline matching method: --text
# Matches a literal text

# This is the default method, the --text part can be omitted.

$ echo 'abc'                    #→ --text abc
$ echo 'abc'                    #→ abc

# Special printf characters as \t and \n are not expanded.

$ echo '\t'                     #→ \t
$ echo '\n'                     #→ \n

# It's a literal text, with no special characters.

$ echo '$'                      #→ $
$ echo '>'                      #→ >
$ echo '?'                      #→ ?
$ echo '!'                      #→ !
$ echo '*'                      #→ *
$ echo '['                      #→ [
$ echo '('                      #→ (

# Blanks are preserved

$ echo '123456789'              #→ 123456789
$ echo '1 3   7 9'              #→ 1 3   7 9
$ echo '    5    '              #→     5    
$ echo ' leading space'         #→  leading space
$ echo '    leading spaces'     #→     leading spaces
$ printf '\tleading tab\n'      #→ 	leading tab
$ printf '\t\tleading tabs\n'   #→ 		leading tabs
$ echo 'trailing space '        #→ trailing space 
$ echo 'trailing spaces    '    #→ trailing spaces    
$ printf 'trailing tab\t\n'     #→ trailing tab	
$ printf 'trailing tabs\t\t\n'  #→ trailing tabs		

# Syntax: Must be exactly one space before and after --text

$ echo 'fail'                   #→   --text fail
$ echo 'fail'                   #→ --text  fail
$ echo 'fail'                   #→ --text	fail

# As seen in all these examples, the final \n is implied.
# You can't match parcial lines
