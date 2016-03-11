# The blank space before the #=> marker matters?

$ echo 'one space' #=> one space
$ echo 'one tab'	#=> one tab
$ echo 'multi spaces'           #=> multi spaces
$ echo 'multi tabs'				#=> multi tabs
$ echo 'mixed'  	 		 	#=> mixed

# Blank lines and comments in the middle.
# No need to 'close' previous command.

# Leading and trailing blank space are preserved?

$ echo ' leading space' #=>  leading space
$ echo '    leading spaces' #=>     leading spaces
$ printf '\tleading tab\n' #=> 	leading tab
$ printf '\t\tleading tabs\n' #=> 		leading tabs
$ echo 'trailing space ' #=> trailing space 
$ echo 'trailing spaces    ' #=> trailing spaces    
$ printf 'trailing tab\t\n' #=> trailing tab	
$ printf 'trailing tabs\t\t\n' #=> trailing tabs		

# Blank output

$ echo ' ' #=>  
$ echo '    ' #=>     
$ printf '\t\n' #=> 	
$ printf '\t\t\t\n' #=> 			
$ printf ' \t  \t\t   \n' #=>  	  		   

# Inline results have precedence over normal results
$ echo "both inline and normal output"  #=> both inline and normal output
Inline wins.
The normal output is just ignored.
$
