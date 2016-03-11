# Inline matching method: --text
# Matches a literal text

# This is the default method, the --text part can be omitted.

$ echo 'abc'                    #=> --text abc
$ echo 'abc'                    #=> abc

# Special characters as \t and \n are not expanded.

$ printf '%s\n' '\t'            #=> \t
$ printf '%s\n' '\n'            #=> \n

# Variables and commands are not parsed (see #=> --eval for that).

$ echo '$PWD'                   #=> $PWD
$ echo '$(date)'                #=> $(date)

# It's a literal text, with no special characters.

$ echo '$'                      #=> $
$ echo '>'                      #=> >
$ echo '?'                      #=> ?
$ echo '!'                      #=> !
$ echo '*'                      #=> *
$ echo '['                      #=> [
$ echo '('                      #=> (

# For commands that return an empty line, just leave it empty

$ echo                          #=> 

# But don't forget the blank space after the →, because in this
# case the #=> marker will be considered a plain comment and ignored

$ echo "not inline output"      #=>
not inline output
$

# Blanks are preserved

$ echo '123456789'              #=> 123456789
$ echo '1 3   7 9'              #=> 1 3   7 9
$ echo '    5    '              #=>     5    
$ echo ' leading space'         #=>  leading space
$ echo '    leading spaces'     #=>     leading spaces
$ printf '\tleading tab\n'      #=> 	leading tab
$ printf '\t\tleading tabs\n'   #=> 		leading tabs
$ echo 'trailing space '        #=> trailing space 
$ echo 'trailing spaces    '    #=> trailing spaces    
$ printf 'trailing tab\t\n'     #=> trailing tab	
$ printf 'trailing tabs\t\t\n'  #=> trailing tabs		
$ echo ' '                      #=>  
$ echo '   '                    #=>  
$ printf '\t\n'                 #=> 	
$ printf '\t\t\t\n'             #=> 			
$ printf ' \t  \t\t   \n'       #=>  	  		   

# As seen in all these examples, the final \n is implied.
# You can't match lines with no \n.

$ printf 'ok\n'                 #=> ok
$ printf 'fail'                 #=> fail

# An easy workaround is to add an empty 'echo' at the end:

$ printf 'ok'; echo             #=> ok

# Syntax: Must be exactly one space before and after --text

$ echo 'fail'                   #=>   --text fail with 2 spaces
$ echo 'fail'                   #=> --text	fail with tab

# Syntax: The extra space after '--text ' is already part of the output

$ echo ' ok'                    #=> --text  ok

# Syntax: The space after --text is required.
# When missing, the '--text' is considered a normal text.

$ echo '--text'                 #=> --text

# Syntax: Make sure we won't catch partial matches.

$ echo '--textual'              #=> --textual

# Syntax: To insert a literal text that begins with '--text '
#         just prefix it with another --text.

$ echo '--text is cool'         #=> --text --text is cool
