# Literate Testing Example

Here's a very simple example of “Literate Testing”, where shell command lines and prose fit together in a technical document that's meant to be read and tested.

* As a reader, you can read the document and learn by the helpful examples.
* As a developer, you can feed the document to `cltest` and it will test it: all the command lines will be executed, in order, and their results checked against those written in the document. This way you can guarantee that all your examples are correct. The prose text is just ignored.

The same technical article appears in 3 different formats and they are fully testable:

* **unix-cut.md** — Using the Markdown format, all the code blocks are prefixed by 4 spaces. You just inform that to `cltest` using the `--prefix 4` command line option:

        ../../cltest --prefix 4 unix-cut.md

* **unix-cut.txt** — A plain text file, using tabs to indent the code blocks. Once again you'll use the `--prefix` option to inform the to program how to find the commands:

        ../../cltest --prefix tab unix-cut.txt

* **unix-cut.github.md** — Using the GitHub flavor of the Markdown format, the code blocks are not indented, but are surrounded by ` ``` ` lines, with optional language name: ` ```bash`. We don't need the `--prefix` option anymore, but now as there's no indent, we need to explicitly close each command line block with an empty prompt `$ `. Running the tests is simple:

        ../../cltest unix-cut.github.md

Play around! Run the tests, change the document's commands to force an error, use the `--verbose` option, ...
