# Syntax: Empty prompt (with space) closes the previous command

$ echo 1
1
$ 

# Syntax: Empty prompt (no space) closes the previous command

$ echo 2
2
$

# Syntax: Repeated empty prompts are OK

$ 
$
$

# Syntax: End-of-file closes the last command

$ echo 3
3
