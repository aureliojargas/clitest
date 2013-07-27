#!/bin/bash
# doctest.sh - Automatic tests for shell script command lines
#              https://github.com/aureliojargas/doctest.sh
# License: MIT
# by Aurelio Jargas (http://aurelio.net), since 2013-07-25

my_name="$(basename "$0")"
my_version='dev'
my_help="\
Usage: $my_name [OPTIONS] <FILES>

Options:
  -1, --abort                 Abort the tests on the first error
      --diff-options STRING   Customize options for diff (default: -u)
      --inline-prefix STRING  Set inline output prefix (default: '#→ ')
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
      --no-color              Turn off colors in the program output
      --prefix STRING         Set command line prefix (default: none)
      --prompt STRING         Set prompt string (default: '$ ')
  -q, --quiet                 Quiet operation, no output shown
  -v, --verbose               Show each test being executed
  -V, --version               Show program version and exit"

# Customization (if needed), some may be altered by command line options
prefix=''
prompt='$ '
inline_prefix='#→ '
diff_options='-u'
ok_file="${TMPDIR:-/tmp}/doctest.ok.$$.txt"
test_output_file="${TMPDIR:-/tmp}/doctest.output.$$.txt"
temp_file="${TMPDIR:-/tmp}/doctest.temp.$$.txt"
# Note: using temporary files for compatibility, since <(...) is not portable.

# Flags (0=off, 1=on), may be altered by command line options
debug=0
quiet=0
verbose=0
list_mode=0
list_run=0
use_colors=1
abort_on_first_error=0

# Do not change these vars
nr_files=0
nr_total_tests=0
nr_total_errors=0
nr_file_tests=0
nr_file_errors=0
files_stat_message=''
original_dir=$(pwd)

# Handle command line options
while test "${1#-}" != "$1"
do
	case "$1" in
		-q|--quiet     ) shift; quiet=1 ;;
		-v|--verbose   ) shift; verbose=1 ;;
		-l|--list      ) shift; list_mode=1;;
		-L|--list-run  ) shift; list_run=1;;
		-1|--abort     ) shift; abort_on_first_error=1 ;;
		--no-color     ) shift; use_colors=0 ;;
  		--debug        ) shift; debug=1 ;;
		--diff-options ) shift; diff_options="$1"; shift ;;
		--inline-prefix) shift; inline_prefix="$1"; shift ;;
		--prompt       ) shift; prompt="$1"; shift ;;
		--prefix       ) shift; prefix="$1"; shift ;;
		-V|--version   ) echo "$my_name $my_version"; exit 0 ;;
		-h|--help      ) echo "$my_help"; exit 0 ;;
		*) break ;;
	esac
done

# Command line options consumed, now it's just the files
nr_files=$#

# No files? Show help.
if test $nr_files -eq 0
then
	echo "$my_help"
	exit 0
fi

# Handy shortcuts for prefixes
case "$prefix" in
	tab)
		prefix=$(printf '\t')
	;;
	0)
		prefix=''
	;;
	[1-9] | [1-9][0-9])  # 1-99
		# convert number to spaces: 2 => '  '
		prefix=$(printf "%${prefix}s" ' ')
	;;
	*\\*)
		prefix="$(printf %b "$prefix")"  # expand \t and others
	;;
esac

# Utilities, prefixed by _ to avoid overwriting command names
_clean_up ()
{
	rm -f "$ok_file" "$test_output_file" "$temp_file"
}
_message ()
{
	local color_code

	test "$quiet" = 1 && return

	case "$1" in
		@red  ) color_code=31; shift;;
		@green) color_code=32; shift;;
		@blue ) color_code=34; shift;;
		@pink ) color_code=35; shift;;
		@cyan ) color_code=36; shift;;
	esac
	# Note: colors must be readable in dark and light backgrounds

	if test "$use_colors" = 1 -a -n "$color_code"
	then
		printf '%b%s%b\n' "\033[${color_code}m" "$*" '\033[m'
	else
		echo "$*"
	fi
}
_debug ()
{
	test "$debug" = 1 && _message @blue "$@"
}
_verbose ()
{
	test "$verbose" = 1 && _message @cyan "$@"
}
_list_line ()  # $1=command $2=ok|fail
{
	# Compose the output lines for --list and --list-run

	local cmd="$1"
	local tab="$(printf '\t')"
	local n=$nr_total_tests

	case "$2" in
		ok)
			# Green line or OK stamp (--list-run)
			if test "$use_colors" -eq 1
			then
				_message @green "${n}${tab}${cmd}"
			else
				_message "${n}${tab}OK${tab}${cmd}"
			fi
		;;
		fail)
			# Red line or FAIL stamp (--list-run)
			if test "$use_colors" -eq 1
			then
				_message @red "${n}${tab}${cmd}"
			else
				_message "${n}${tab}FAIL${tab}${cmd}"
			fi
		;;
		*)
			# Normal line, no color, no stamp (--list)
			_message "${n}${tab}${cmd}"
		;;
	esac
}
_run_test ()  # $1=command
{
	local diff
	local failed
	local cmd="$1"; shift

	nr_total_tests=$((nr_total_tests + 1))
	nr_file_tests=$((nr_file_tests + 1))

	# List mode: just show the command (no execution)
	if test "$list_mode" = 1
	then
		_list_line "$cmd"
		return 0
	fi

	_verbose "======= $cmd"
	#_debug "[ EVAL  ] $cmd"

	# Execute the command, saving STDOUT and STDERR to a file
	eval "$cmd" > "$test_output_file" 2>&1

	#_debug "[OUTPUT ] $(cat "$test_output_file")"

	diff=$(diff $diff_options "$ok_file" "$test_output_file")
	failed=$?

	# Test failed :(
	if test $failed -eq 1
	then
		nr_file_errors=$((nr_file_errors + 1))
		nr_total_errors=$((nr_total_errors + 1))

		# Decide the message format
		if test "$list_run" = 1
		then
			# List mode
			_list_line "$cmd" fail
		else
			# Normal mode: show FAILED message and the diff
			_message
			_message @red "FAILED: $cmd"
			test "$quiet" = 1 || echo "$diff" | sed '1,2 d'  # no +++/--- headers
		fi

		# Should I abort now?
		if test $abort_on_first_error -eq 1
		then
			_clean_up
			exit 1
		fi

	# Test OK
	else
		test "$list_run" = 1 && _list_line "$cmd" ok
	fi

	# Reset holder for the OK output
	> "$ok_file"
}
_process_test_file ()  # $1=filename
{
	local test_command
	local ok_text
	local file="$1"

	# reset globals
	nr_file_tests=0
	nr_file_errors=0

	# Loop for each line of input file
	# Note: changing IFS to avoid right-trimming of spaces/tabs
	# Note: read -r to preserve the backslashes (also works in dash shell)
	while IFS='' read -r input_line
	do
		case "$input_line" in

			# Prompt alone: closes previous command line (if any)
			"$prefix$prompt" | "$prefix${prompt% }" | "$prefix$prompt ")
				#_debug "[ CLOSE ] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Reset current command holder
				test_command=
			;;

			# This line is a command line to be tested
			"$prefix$prompt"*)
				#_debug "[CMDLINE] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Remove the prompt
				test_command="${input_line#$prefix$prompt}"

				# This is a special test with inline output?
				if echo "$test_command" | grep "$inline_prefix" > /dev/null
				then
					# Separate command from inline output
					test_command="${test_command%$inline_prefix*}"
					ok_text="${input_line##*$inline_prefix}"

					#_debug "[NEW CMD] $test_command"
					#_debug "[OK TEXT] $ok_text"

					# Save the output and run test
					echo "$ok_text" > "$ok_file"
					_run_test "$test_command"

					# Reset current command holder, since we're done
					test_command=
				else
					# It's a normal command line, output begins in next line

					# Reset holder for the OK output
					> "$ok_file"

					#_debug "[NEW CMD] $test_command"
				fi
			;;

			# Test output, blank line or comment
			*)
				#_debug "[ ? LINE] $input_line"

				# Ignore this line if there's no pending test
				test -n "$test_command" || continue

				# Required prefix is missing: we just left a command block
				if test -n "$prefix" -a "${input_line#$prefix}" = "$input_line"
				then
					#_debug "[BLOKOUT] $input_line"

					# Run the pending test and reset
					_run_test "$test_command"
					test_command=
				fi

				# This line is a test output, save it (without prefix)
				echo "${input_line#$prefix}" >> "$ok_file"

				#_debug "[OK LINE] $input_line"
			;;
		esac
	done < "$file"

	#_debug "[LOOPOUT] test_command: $test_command"

	# Run pending tests
	test -n "$test_command" && _run_test "$test_command"
}


# Loop for each input file
while test -n "$1"
do
	test_file="$1"
	shift

	# Some tests may "cd" to another dir, we need to get back
	# to preserve the relative paths of the input files
	cd "$original_dir"

	# Abort when test file not found/readable
	if ! test -f "$test_file" -a -r "$test_file"
	then
		_message "$(basename "$0"): Error: cannot read input file: $test_file"
		exit 1
	fi

	# In multifile mode, identify the current file
	if test $nr_files -gt 1 -a "$list_mode" -ne 1 -a "$list_run" -ne 1
	then
		_message "Testing file $test_file"
	fi

	### Prepare input file
	#
	# This sed has two purposes:
	# 1. add \n to last line (if missing), otherwise while loop will ignore it
	# 2. convert Windows files (CRLF) to the Unix format (LF)
	#
	# Note: the temporary file is required, because doing "sed | while" opens
	#       a subshell and global vars won't be updated outside the loop.
	#
	sed "s/$(printf '\r')$//" "$test_file" > "$temp_file"

	# The magic happens here
	_process_test_file "$temp_file"

	# Abort when no test found
	if test $nr_file_tests -eq 0
	then
		_message "$(basename "$0"): Error: no test found in input file: $test_file"
		exit 1
	fi

	# Compose file stats message
	nr_file_ok=$((nr_file_tests - nr_file_errors))
	if test $nr_file_errors -eq 0
	then
		msg=$(printf '%2d ok           %s' $nr_file_ok "$test_file")
	else
		msg=$(printf '%2d ok, %2d fail  %s' $nr_file_ok $nr_file_errors "$test_file")
	fi

	# Append file stats to global holder
	files_stat_message=$(printf '%s\n%s' "$files_stat_message" "$msg")
done

_clean_up

# List mode has no stats
test "$list_mode" -eq 1 -o "$list_run" -eq 1 && exit 0

# Show stats
if test $nr_files -gt 1
then
	_message
	_message '--------------------------------------------------'
	_message "${files_stat_message#?}"  # remove \n at start
	_message '--------------------------------------------------'
	_message
fi

# The final message: WIN or FAIL?
if test $nr_total_errors -eq 0
then
	if test $nr_total_tests -eq 1
	then
		_message "$(_message @green OK!) The single test has passed."
	elif test $nr_total_tests -lt 50
	then
		_message "$(_message @green OK!) All $nr_total_tests tests have passed."
	elif test $nr_total_tests -lt 100
	then
		_message "$(_message @green YOU WIN!) All $nr_total_tests tests have passed."
	else
		_message "$(_message @green YOU WIN! PERFECT!) All $nr_total_tests tests have passed."
	fi
	exit 0
else
	test $nr_files -eq 1 && _message  # separate from previous error message

	if test $nr_total_tests -eq 1
	then
		_message "$(_message @red FAIL:) The single test has failed."
	elif test $nr_total_errors -eq $nr_total_tests -a $nr_total_errors -lt 50
	then
		_message "$(_message @red COMPLETE FAIL!) All $nr_total_tests tests have failed."
	elif test $nr_total_errors -eq $nr_total_tests
	then
		_message "$(_message @red EPIC FAIL!) All $nr_total_tests tests have failed."
	else
		_message "$(_message @red FAIL:) $nr_total_errors of $nr_total_tests tests have failed."
	fi
	exit 1
fi
# Note: Those messages are for FUN. When automating, check the exit code.

# Dev notes:
# - Comment   all debug lines: sed 's/	_debug/	#_debug/'
# - Uncomment all debug lines: sed 's/#_debug/_debug/'
