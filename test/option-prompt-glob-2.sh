/// Gotcha: glob chars as --prompt: ? * # % ## %% #* *# %* *%

/// Inline output

?echo 'prompt ?'	#=> prompt ?
*echo 'prompt *'	#=> prompt *
#echo 'prompt #'	#=> prompt #
%echo 'prompt %'	#=> prompt %
##echo 'prompt ##'	#=> prompt ##
%%echo 'prompt %%'	#=> prompt %%
#*echo 'prompt #*'	#=> prompt #*
*#echo 'prompt *#'	#=> prompt *#
%*echo 'prompt %*'	#=> prompt %*
*%echo 'prompt *%'	#=> prompt *%


/// Normal output

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

##echo 'prompt ##'
prompt ##
##

%%echo 'prompt %%'
prompt %%
%%

#*echo 'prompt #*'
prompt #*
#*

*#echo 'prompt *#'
prompt *#
*#

%*echo 'prompt %*'
prompt %*
%*

*%echo 'prompt *%'
prompt *%
*%
