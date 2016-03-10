/// Gotcha: glob chars as --prompt: ? * # %

/// Note: These tests are separated from the two chars globs
///        to avoid partial matches with wrong output.

/// Inline output (one char)

?echo 'prompt ?'	#=> prompt ?
*echo 'prompt *'	#=> prompt *
#echo 'prompt #'	#=> prompt #
%echo 'prompt %'	#=> prompt %

/// Normal output (one char)

?echo 'prompt ?'
prompt ?
?

*echo 'prompt *'
prompt *
*

#echo 'prompt #'
prompt #
#

%echo 'prompt %'
prompt %
%
