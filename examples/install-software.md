# How to install txt2tags v2.6

> This file is an example of a technical “how to” document
> that can also be automatically tested:
> `clitest --prefix tab install-software.md`


## 1. Prepare

First, move to the temporary directory, where we will download, extract
and test the txt2tags package before installing it to the system.

	$ cd /tmp


## 2. Download

Download the .tgz file for the version 2.6, directly from Google Code.

	$ url="https://fossies.org/linux/privat/txt2tags-2.6.tgz"
	$ curl -O -s -S "$url"


## 3. Verify

Let's verify if the downloaded package is not corrupted, by checking
the file size and the total number of files inside the tgz.

	$ du -h txt2tags-2.6.tgz
	532K	txt2tags-2.6.tgz
	$ tar tzf txt2tags-2.6.tgz | sed -n '$='
	545

> Note: Using `sed` to count lines because the output format of `wc -l`
> differs between implementations, regarding leading blank spaces.


## 4. Extract

Since the download is ok, now we can extract the package's files. If
`tar` shows no message, it's because everything went fine and all the
files were extracted.

	$ tar xzf txt2tags-2.6.tgz

A new `txt2tags-2.6` directory was created. Let's enter into it and
list the main files, just to be sure.

	$ cd txt2tags-2.6
	$ ls -1F
	COPYING
	ChangeLog
	README
	doc/
	extras/
	po/
	samples/
	test/
	txt2tags*


## 5. Test

The main `txt2tags` file is executable? Python is installed? Python
version is compatible with the program? So many questions... But a
simple command answers them all.
	
	$ ./txt2tags -V
	txt2tags version 2.6 <http://txt2tags.org>

If the version was shown, it's a proof that the program was run
successfully: Python is installed and it's compatible.

## 6. Install

By default, the program is installed in the `~/bin` user directory.
Usually this directory is already there, but let's play safe and create
it if necessary.

	$ test -d ~/bin || mkdir ~/bin

The install process itself is just a simple file copy.

	$ cp txt2tags ~/bin/

Now just a final test, executing the program directly from `~/bin`.
	
	$ ~/bin/txt2tags -V
	txt2tags version 2.6 <http://txt2tags.org>

Ok, we're done.
