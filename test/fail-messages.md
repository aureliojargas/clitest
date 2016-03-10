# Fail Messages

## inline text

	$ echo fail  #=> ok
	$ echo fail  #=> --eval echo ok

## normal command

	$ echo fail
	ok
	$ echo fail
	ok 1
	ok 2
	ok 3
	$

## inline --file

	$ echo fail  #=> --file lorem-ipsum.txt

## inline --lines

	$ echo fail  #=> --lines 9

## inline --egrep

	$ echo fail  #=> --egrep ^[0-9]+$

## inline --perl

	$ echo fail  #=> --perl ^[0-9]+$

## inline --regex

	$ echo fail  #=> --regex ^[0-9]+$
