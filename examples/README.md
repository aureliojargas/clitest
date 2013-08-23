# clitest Examples

Here's some simple examples to show you how a test file looks like.


## Pure CLI Tests

Take a look at the `.txt` files. They're just like a shell session
snapshot. You have the `$ ` prompt, the command to be executed, and
the results.

```
$ echo "Hello World"
Hello World
$
```

To test these files, just call `clitest` with no options.

```
$ clitest intro.txt
#1	echo "Hello World"
#2	cd /tmp
#3	pwd
#4	cd "$OLDPWD"
OK: 4 of 4 tests passed
$
```

### Easily create your own test files:

1. Go to your terminal
2. Set your prompt accordingly: `PS1='$ '`
3. Type and run the desired commands
4. Copy & paste it all into a text file
5. Done



## Documentation Tests
 
Now take a look at the `.md` files. They're normal Markdown documents
(with titles, paragraphs, code blocks), created to be read by humans
(after HTML conversion).

Inside the code blocks there are examples of command lines and their
results. `clitest` can extract and run these commands for you! Now you
can guarantee that all your examples are correct.

```
$ clitest --prefix tab cut.md
#1	echo "one:two:three:four:five:six" | cut -d : -f 1
#2	echo "one:two:three:four:five:six" | cut -d : -f 4
#3	echo "one:two:three:four:five:six" | cut -d : -f 1,4
#4	echo "one:two:three:four:five:six" | cut -d : -f 4,1
#5	echo "one:two:three:four:five:six" | cut -d : -f 1-4
#6	echo "one:two:three:four:five:six" | cut -d : -f 4-
OK: 6 of 6 tests passed
$
```

Note that since the code blocks in these Markdown documents are
prefixed by a tab, you must use the `--prefix` option.

Even this `README.md` file you're reading is testable. No options
needed, since the code blocks here do not use prefixes.


## Play Around

Run the tests, change the expected output to force a test fail, use
the `--list-run` option, ...
