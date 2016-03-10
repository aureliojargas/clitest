$ echo "error: malformed regex"  #=> --egrep (


# Some grep errors:

# $ echo | egrep '(' ; echo $?
# egrep: parentheses not balanced
# 2
# $ echo | egrep '[' ; echo $?
# egrep: brackets ([ ]) not balanced
# 2
# $ echo | egrep '**' ; echo $?
# egrep: repetition-operator operand invalid
# 2
# $ echo | egrep '{' ; echo $?
# 1
# $
