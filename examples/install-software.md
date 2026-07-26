# How to install txt2tags v2.6

> This file is an example of a technical “how to” document
> that can also be automatically tested:
> `clitest install-software.md`


## 1. Prepare

First, move to the temporary directory, where we will download, extract
and test the txt2tags package before installing it to the system.

```console
$ cd /tmp
$
```


## 2. Download

Download the .tgz file for the version 2.6.

```console
$ url="https://github.com/txt2tags/old/raw/master/txt2tags-2.6.tgz"
$ curl -fsSOL "$url"
$
```


## 3. Verify

Let's verify if the downloaded package is not corrupted, by checking
the file size and the total number of files inside the tgz.

```console
$ du -h txt2tags-2.6.tgz
532K	txt2tags-2.6.tgz
$ tar tzf txt2tags-2.6.tgz | sed -n '$='
545
$
```

> Note: Using `sed` to count lines because the output format of `wc -l`
> differs between implementations, regarding leading blank spaces.


## 4. Extract

Since the download is ok, now we can extract the package's files. If
`tar` shows no message, it's because everything went fine and all the
files were extracted.

```console
$ tar xzf txt2tags-2.6.tgz
$
```

A new `txt2tags-2.6` directory was created. Let's enter into it and
list the main files, just to be sure.

```console
$ cd txt2tags-2.6
$ ls -1F | LC_ALL=C sort
COPYING
ChangeLog
README
doc/
extras/
po/
samples/
test/
txt2tags*
$
```


## 5. Install

In this tutorial, we don't want to change anything in the user's system.
Thus, the program is installed in the `/tmp/bin` user directory. Let's
create it if necessary.

```console
$ bin_dir=/tmp/bin
$ test -d $bin_dir || mkdir $bin_dir
$
```

The install process itself is just a simple file copy.

```console
$ cp -v txt2tags $bin_dir
'txt2tags' -> '/tmp/bin/txt2tags'
$
```

Ok, we're done.
