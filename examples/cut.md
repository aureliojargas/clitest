The numeric ranges of the Unix command "cut"
============================================

Use single numbers to extract one specific field:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1
	one
	$ echo "one:two:three:four:five:six" | cut -d : -f 4
	four

Use commas to inform more than one field:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1,4
	one:four

Note that inverting the order will *not* invert the output:

	$ echo "one:two:three:four:five:six" | cut -d : -f 4,1
	one:four

Use an hyphen to inform a range of fields, from one to four:

	$ echo "one:two:three:four:five:six" | cut -d : -f 1-4
	one:two:three:four

If you omit the second range number, it matches until the last:

	$ echo "one:two:three:four:five:six" | cut -d : -f 4-
	four:five:six

cut is cool, isn't it?

> Note: To automatically test all the shell commands in this article,
> just run: `clitest --prefix tab cut.md`
