/// Gotcha: glob chars as --prefix: ? * # ## #* *# #*# % %% %* *% %*%

/// Inline output

?$ echo 'prefix ?'	#=> prefix ?
*$ echo 'prefix *'	#=> prefix *
#$ echo 'prefix #'	#=> prefix #
%$ echo 'prefix %'	#=> prefix %
##$ echo 'prefix ##'	#=> prefix ##
%%$ echo 'prefix %%'	#=> prefix %%
#*$ echo 'prefix #*'	#=> prefix #*
*#$ echo 'prefix *#'	#=> prefix *#
%*$ echo 'prefix %*'	#=> prefix %*
*%$ echo 'prefix *%'	#=> prefix *%

/// Normal output

?$ echo 'prefix ?'
?prefix ?
?$

*$ echo 'prefix *'
*prefix *
*$

#$ echo 'prefix #'
#prefix #
#$

%$ echo 'prefix %'
%prefix %
%$

##$ echo 'prefix ##'
##prefix ##
##$

%%$ echo 'prefix %%'
%%prefix %%
%%$

#*$ echo 'prefix #*'
#*prefix #*
#*$

*#$ echo 'prefix *#'
*#prefix *#
*#$

%*$ echo 'prefix %*'
%*prefix %*
%*$

*%$ echo 'prefix *%'
*%prefix *%
*%$
