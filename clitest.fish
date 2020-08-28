#!/usr/bin/env fish
# clitest - Tester for Unix command lines
#
# Author:  Aurelio Jargas (http://aurelio.net)
# Created: 2013-07-24
# License: MIT
# GitHub:  https://github.com/aureliojargas/clitest
#
# Exit codes:
#   0  All tests passed, or normal operation (--help, --list, ...)
#   1  One or more tests have failed
#   2  An error occurred (file not found, invalid range, ...)
#
# Test environment:
#   By default, the tests will run in the current working directory ($PWD).
#   You can change to another dir normally using 'cd' inside the test file.
#   All the tests are executed in the same shell session, using eval. Test
#   data such as variables and working directory will persist between tests.
#
# Namespace:
#   All variables and functions in this script are prefixed by 'tt_' to
#   avoid clashing with test's variables, functions, aliases and commands.

set -g tt_my_name (basename (status -f))
set -g tt_my_url 'https://github.com/aureliojargas/clitest'
set -g tt_my_version 'dev'

# Customization (if needed, edit here or use the command line options)
set -g tt_prefix ''
set -g tt_prompt '$ '
set -g tt_inline_prefix '#=> '
set -g tt_diff_options '-u'
set -g tt_color_mode 'auto' # auto, always, never
set -g tt_progress 'test' # test, number, dot, none


# End of customization

# --help message, keep it simple, short and informative
set -g tt_my_help "\
Usage: $tt_my_name [options] <file ...>

Options:
  -1, --first                 Stop execution upon first failed test
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
  -t, --test RANGE            Run specific tests, by number (1,2,4-7)
  -s, --skip RANGE            Skip specific tests, by number (1,2,4-7)
      --pre-flight COMMAND    Execute command before running the first test
      --post-flight COMMAND   Execute command after running the last test
  -q, --quiet                 Quiet operation, no output shown
  -V, --version               Show program version and exit

Customization options:
  -P, --progress TYPE         Set progress indicator: test, number, dot, none
      --color WHEN            Set when to use colors: auto, always, never
      --diff-options OPTIONS  Set diff command options (default: '$tt_diff_options')
      --inline-prefix PREFIX  Set inline output prefix (default: '$tt_inline_prefix')
      --prefix PREFIX         Set command line prefix (default: '$tt_prefix')
      --prompt STRING         Set prompt string (default: '$tt_prompt')

See also: $tt_my_url"

# Flags (0=off, 1=on), most can be altered by command line options
set -g tt_debug 0
set -g tt_use_colors 0
set -g tt_stop_on_first_fail 0
set -g tt_separator_line_shown 0

# The output mode values are mutually exclusive
set -g tt_output_mode 'normal' # normal, quiet, list, list-run


# Globals (all variables are globals, for better portability)
set -g tt_nr_files 0
set -g tt_nr_total_tests 0
set -g tt_nr_total_fails 0
set -g tt_nr_total_skips 0
set -g tt_nr_file_tests 0
set -g tt_nr_file_fails 0
set -g tt_nr_file_skips 0
set -g tt_nr_file_ok 0
set -g tt_files_stats
set -g tt_original_dir (pwd)
set -g tt_pre_command
set -g tt_post_command
set -g tt_run_range
set -g tt_run_range_data
set -g tt_skip_range
set -g tt_skip_range_data
set -g tt_failed_range
set -g tt_temp_dir
set -g tt_test_file
set -g tt_input_line
set -g tt_line_number 0
set -g tt_test_number 0
set -g tt_test_line_number 0
set -g tt_test_command
set -g tt_test_inline
set -g tt_test_mode
set -g tt_test_status 2
set -g tt_test_output
set -g tt_test_exit_code
set -g tt_test_diff
set -g tt_test_ok_text
set -g tt_missing_nl 0

# Special handy chars
set -g tt_tab '	'
set -g tt_nl '
'

### Utilities

function tt_clean_up
    test -n "$tt_temp_dir" && rm -rf "$tt_temp_dir"
end
function tt_message
    test "$tt_output_mode" = 'quiet' && return 0
    test $tt_missing_nl -eq 1 && echo
    printf '%s\n' "$argv"
    set -g tt_separator_line_shown 0
    set -g tt_missing_nl 0
end
function tt_message_part  # no line break
    test "$tt_output_mode" = 'quiet' && return 0
    printf '%s' "$argv"
    set -g tt_separator_line_shown 0
    set -g tt_missing_nl 1
end
function tt_error
    test $tt_missing_nl -eq 1 && echo
    printf '%s\n' "$tt_my_name: Error: $argv[1]" >&2
    exit 2
end
function tt_debug  # $argv[1]=id, $argv[2]=contents
    test $tt_debug -ne 1 && return 0
    if test INPUT_LINE = $argv[1]
        # Original input line is all cyan and preceded by separator line
        printf -- "{$tt_color_cyan}%s{$tt_color_off}\n" (tt_separator_line)
        printf -- "{$tt_color_cyan}-- %10s[%s]{$tt_color_off}\n" $argv[1] $argv[2]
    else
        # Highlight tabs and the (last) inline prefix
        printf -- "{$tt_color_cyan}-- %10s[{$tt_color_off}%s{$tt_color_cyan}]{$tt_color_off}\n" $argv[1] $argv[2] |
            sed "/LINE_CMD/ s/\(.*\)\($tt_inline_prefix\)/\1{$tt_color_red}\2{$tt_color_off}/" |
            sed "s/$tt_tab/{$tt_color_green}<tab>{$tt_color_off}/g"
    end
end
function tt_separator_line
    printf "%{$COLUMNS}s" ' ' | tr ' ' -
end
function tt_list_test  # $argv[1]=normal|list|ok|fail
    # Show the test command in normal mode, --list and --list-run
    switch $argv[1]
        case normal list
            # Normal line, no color, no stamp (--list)
            tt_message "#{$tt_test_number}{$tt_tab}{$tt_test_command}"
        case ok
            # Green line or OK stamp (--list-run)
            if test $tt_use_colors -eq 1
                tt_message "{$tt_color_green}#{$tt_test_number}{$tt_tab}{$tt_test_command}{$tt_color_off}"
            else
                tt_message "#{$tt_test_number}{$tt_tab}OK{$tt_tab}{$tt_test_command}"
            end
        case fail
            # Red line or FAIL stamp (--list-run)
            if test $tt_use_colors -eq 1
                tt_message "{$tt_color_red}#{$tt_test_number}{$tt_tab}{$tt_test_command}{$tt_color_off}"
            else
                tt_message "#{$tt_test_number}{$tt_tab}FAIL{$tt_tab}{$tt_test_command}"
            end
    end
end
function tt_parse_range  # $argv[1]=range
    # Parse numeric ranges and output them in an expanded format
    #
    #     Supported formats             Expanded
    #     ------------------------------------------------------
    #     Single:  1                    :1:
    #     List:    1,3,4,7              :1:3:4:7:
    #     Range:   1-4                  :1:2:3:4:
    #     Mixed:   1,3,4-7,11,13-15     :1:3:4:5:6:7:11:13:14:15:
    #
    #     Reverse ranges and repeated/unordered numbers are ok.
    #     Later we will just grep for :number: in each test.

    switch $argv[1]
        case 0 ''
            # No range, nothing to do
            return 0
        case *[!0-9,-]*  # XXX not supported
            # Error: strange chars, not 0123456789,-
            return 1
    end

    # OK, all valid chars in range, let's parse them

    set -g tt_part
    set -g tt_n1
    set -g tt_n2
    set -g tt_swap
    set -g tt_range_data ':'   # :1:2:4:7:

    # Loop each component: a number or a range
    for tt_part in (echo $argv[1] | tr , ' ')
        # If there's an hyphen, it's a range
        switch "$tt_part"
            case *-*
                # Error: Invalid range format, must be: number-number
                echo "$tt_part" | grep '^[0-9][0-9]*-[0-9][0-9]*$' > /dev/null || return 1

                set -g tt_n1 (string split - $tt_part)[1]
                set -g tt_n2 (string split - $tt_part)[2]

                # Negative range, let's just reverse it (5-1 => 1-5)
                if test "$tt_n1" -gt "$tt_n2"
                    set -g tt_swap $tt_n1
                    set -g tt_n1 $tt_n2
                    set -g tt_n2 $tt_swap
                end

                # Expand the range (1-4 => 1:2:3:4)
                set -g tt_part $tt_n1:
                while test "$tt_n1" -ne "$tt_n2"
                    set -g tt_n1 (math $tt_n1 + 1)
                    set -g tt_part $tt_part$tt_n1:
                end
                set -g tt_part (string replace --regex ':$' '' $tt_part)
        end

        # Append the number or expanded range to the holder
        test "$tt_part" != 0 && set tt_range_data $tt_range_data$tt_part:
    end

    test "$tt_range_data" != ':' && echo "$tt_range_data"
    return 0
end
function tt_reset_test_data
    set -g tt_test_command
    set -g tt_test_inline
    set -g tt_test_mode
    set -g tt_test_status 2
    set -g tt_test_output
    set -g tt_test_diff
    set -g tt_test_ok_text
end
function tt_run_test
    set -g tt_test_number (math $tt_test_number + 1)
    set -g tt_nr_total_tests (math $tt_nr_total_tests + 1)
    set -g tt_nr_file_tests (math $tt_nr_file_tests + 1)

    # Run range on: skip this test if it's not listed in $tt_run_range_data
    if test -n "$tt_run_range_data" && string match -qve ":$tt_test_number:" "$tt_run_range_data"
        set -g tt_nr_total_skips (math $tt_nr_total_skips + 1)
        set -g tt_nr_file_skips (math $tt_nr_file_skips + 1)
        tt_reset_test_data
        return 0
    end

    # Skip range on: skip this test if it's listed in $tt_skip_range_data
    # Note: --skip always wins over --test, regardless of order
    if test -n "$tt_skip_range_data" && string match -qe ":$tt_test_number:" "$tt_skip_range_data"
        set -g tt_nr_total_skips (math $tt_nr_total_skips + 1)
        set -g tt_nr_file_skips (math $tt_nr_file_skips + 1)
        tt_reset_test_data
        return 0
    end

    switch "$tt_output_mode"
        case normal
            # Normal mode: show progress indicator
            switch "$tt_progress"
                case test
                    tt_list_test normal
                case number
                    tt_message_part "$tt_test_number "
                case none
                    :
                case '*'
                    tt_message_part "$tt_progress"
            end
        case list
            # List mode: just show the command and return (no execution)
            tt_list_test list
            tt_reset_test_data
            return 0
    end

    tt_debug EVAL "$tt_test_command"

    # Execute the test command, saving output (STDOUT and STDERR)
    eval "$tt_test_command" > "$tt_test_output_file" 2>&1 < /dev/null
    set -g tt_test_exit_code $status

    tt_debug OUTPUT (cat "$tt_test_output_file")

    # The command output matches the expected output?
    switch $tt_test_mode
        case output
            printf %s "$tt_test_ok_text" > "$tt_test_ok_file"
            set -g tt_test_diff (diff $tt_diff_options "$tt_test_ok_file" "$tt_test_output_file")
            set -g tt_test_status $status
        case '*'
            tt_error "unknown test mode '$tt_test_mode'"
    end

    # Test failed :(
    if test $tt_test_status -ne 0
        set -g tt_nr_file_fails (math $tt_nr_file_fails + 1)
        set -g tt_nr_total_fails (math $tt_nr_total_fails + 1)
        set -g tt_failed_range "$tt_failed_range$tt_test_number,"

        # Decide the message format
        if test "$tt_output_mode" = 'list-run'
            # List mode
            tt_list_test fail
        else
            # Normal mode: show FAILED message and the diff
            if test $tt_separator_line_shown -eq 0 # avoid dups
                tt_message {$tt_color_red}(tt_separator_line){$tt_color_off}
            end
            tt_message "{$tt_color_red}[FAILED #$tt_test_number, line $tt_test_line_number] $tt_test_command{$tt_color_off}"
            tt_message "$tt_test_diff" | sed '1 { /^--- / { N; /\n+++ /d; }; }'  # no ---/+++ headers
            tt_message {$tt_color_red}(tt_separator_line){$tt_color_off}
            set -g tt_separator_line_shown 1
        end

        # Should I abort now?
        if test $tt_stop_on_first_fail -eq 1
            exit 1
        end

    # Test OK
    else
        test "$tt_output_mode" = 'list-run' && tt_list_test ok
    end

    tt_reset_test_data
end
function tt_process_test_file
    # Reset counters
    set -g tt_nr_file_tests 0
    set -g tt_nr_file_fails 0
    set -g tt_nr_file_skips 0
    set -g tt_line_number 0
    set -g tt_test_line_number 0

    # Loop for each line of input file
    # Note: fish 'read' preserve backslashes and do not trim whitespace
    while read tt_input_line || test -n "$tt_input_line"
        set -g tt_line_number (math $tt_line_number + 1)
        tt_debug INPUT_LINE "$tt_input_line"

        switch "$tt_input_line"

            case "$tt_prefix$tt_prompt" $tt_prefix(string replace --regex ' $' '' $tt_prompt) "$tt_prefix$tt_prompt "
                # Prompt alone: closes previous command line (if any)

                tt_debug 'LINE_$' "$tt_input_line"

                # Run pending tests
                test -n "$tt_test_command" && tt_run_test

            case "$tt_prefix$tt_prompt*"
                # This line is a command line to be tested

                tt_debug LINE_CMD "$tt_input_line"

                # Run pending tests
                test -n "$tt_test_command" && tt_run_test

                # Remove the prompt
                set -g tt_test_command (
                    string replace --regex ^(
                        string escape --style=regex $tt_prefix$tt_prompt
                    ) '' $tt_input_line
                )

                # Save the test's line number for future messages
                set -g tt_test_line_number $tt_line_number

                # This is a special test with inline output? No. XXX
                # It's a normal command line, output begins in next line
                set -g tt_test_mode 'output'

                tt_debug NEW_CMD "$tt_test_command"

            case '*'
                # Test output, blank line or comment

                tt_debug 'LINE_MISC' "$tt_input_line"

                # Ignore this line if there's no pending test
                test -n "$tt_test_command" || continue

                # Required prefix is missing: we just left a command block
                if test -n "$tt_prefix" && string match -qve $tt_prefix $tt_input_line
                    tt_debug BLOCK_OUT "$tt_input_line"

                    # Run the pending test and we're done in this line
                    tt_run_test
                    continue
                end

                # This line is a test output, save it (without prefix)
                set -g tt_test_ok_text $tt_test_ok_text(
                    string replace --regex ^(
                        string escape --style=regex $tt_prefix
                    ) '' $tt_input_line
                )$tt_nl

                tt_debug OK_TEXT (
                    string replace --regex ^(
                        string escape --style=regex $tt_prefix
                    ) '' $tt_input_line
                )
        end
    end < "$tt_temp_file"

    tt_debug LOOP_OUT "\$tt_test_command=$tt_test_command"

    # Run pending tests
    test -n "$tt_test_command" && tt_run_test
end
function tt_make_temp_dir
    # Create private temporary dir and sets global $tt_temp_dir.
    # http://mywiki.wooledge.org/BashFAQ/062

    # Prefer mktemp when available
    test -n $TMPDIR && set TMPDIR /tmp
    set -g tt_temp_dir (mktemp -d "$TMPDIR/clitest.XXXXXX" 2> /dev/null)
end

### Init process

# Handle command line options
while string match -qr -- '^-' $argv[1]
    switch $argv[1]
        case -1 --first
            shift
            set -g tt_stop_on_first_fail 1
        case -l --list
            shift
            set -g tt_output_mode 'list'
        case -L --list-run
            shift
            set -g tt_output_mode 'list-run'
        case -q --quiet
            shift
            set -g tt_output_mode 'quiet'
        case -t --test
            shift
            set -g tt_run_range $argv[1]
            shift
        case -s --skip
            shift
            set -g tt_skip_range $argv[1]
            shift
        case --pre-flight
            shift
            set -g tt_pre_command $argv[1]
            shift
        case --post-flight
            shift
            set -g tt_post_command $argv[1]
            shift
        case -P --progress
            shift
            set -g tt_progress $argv[1]
            set -g tt_output_mode 'normal'
            shift
        case --color --colour
            shift
            set -g tt_color_mode $argv[1]
            shift
        case --diff-options
            shift
            set -g tt_diff_options $argv[1]
            shift
        case --inline-prefix
            shift
            set -g tt_inline_prefix $argv[1]
            shift
        case --prefix
            shift
            set -g tt_prefix $argv[1]
            shift
        case --prompt
            shift
            set -g tt_prompt $argv[1]
            shift
        case -h --help
            printf '%s\n' "$tt_my_help"
            exit 0
        case -V --version
            printf '%s %s\n' "$tt_my_name" "$tt_my_version"
            exit 0
        case --debug
            # Undocumented dev-only option
            shift
            set -g tt_debug 1
        case --
            # No more options to process
            shift
            break
        case -
            # Argument - means "read test file from STDIN"
            break
        case '*'
            tt_error "invalid option $argv[1]"
    end
end

# Command line options consumed, now it's just the files
set -g tt_nr_files (count $argv)

# No files?
if test $tt_nr_files -eq 0
    tt_error 'no test file informed (try --help)'
end

# Handy shortcuts for prefixes
switch "$tt_prefix"
    case tab
        set -g tt_prefix "$tt_tab"
    case 0
        set -g tt_prefix ''
    case 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20  # XXX [1-9] [1-9][0-9]  # 1-99 not supported
        # convert number to spaces: 2 => '  '
        set -g tt_prefix (printf "%{$tt_prefix}s" ' ')
    case '*\\*'
        set -g tt_prefix (printf %b "$tt_prefix")  # expand \t and others
end

# Validate and normalize progress value
if test "$tt_output_mode" = 'normal'
    switch "$tt_progress"
        case test
            :
        case number n   # [0-9] not supported
            set -g tt_progress 'number'
        case dot .
            set -g tt_progress '.'
        case none no
            set -g tt_progress 'none'
        case '?'  # Single char, use it as the progress
            :
        case '*'
            tt_error "invalid value '$tt_progress' for --progress. Use: test, number, dot or none."
    end
end

# Will we use colors in the output?
switch "$tt_color_mode"
    case always yes y
        set -g tt_use_colors 1
    case never no n
        set -g tt_use_colors 0
    case auto a
        # The auto mode will use colors if the output is a terminal
        # Note: test -t is in POSIX
        if test -t 1
            set -g tt_use_colors 1
        else
            set -g tt_use_colors 0
        end
    case '*'
        tt_error "invalid value '$tt_color_mode' for --color. Use: auto, always or never."
end

# Set colors
# Remember: colors must be readable in dark and light backgrounds
# Customization: tweak the numbers after [ to adjust the colors
if test $tt_use_colors -eq 1
    set -g tt_color_red (  printf '\033[31m')  # fail
    set -g tt_color_green (printf '\033[32m')  # ok
    set -g tt_color_cyan ( printf '\033[36m')  # debug
    set -g tt_color_off (  printf '\033[m')
end

# Find the terminal width
# The COLUMNS env var is set by Bash (must be exported in ~/.bashrc).
# In other shells, try to use 'tput cols' (not POSIX).
# If not, defaults to 50 columns, a conservative amount.
test -n $COLUMNS && set COLUMNS (tput cols 2> /dev/null)
test -n $COLUMNS && set COLUMNS 50

# Parse and validate --test option value, if informed
set -g tt_run_range_data (tt_parse_range "$tt_run_range")
if test $status -ne 0
    tt_error "invalid argument for -t or --test: $tt_run_range"
end

# Parse and validate --skip option value, if informed
set -g tt_skip_range_data (tt_parse_range "$tt_skip_range")
if test $status -ne 0
    tt_error "invalid argument for -s or --skip: $tt_skip_range"
end

### Real execution begins here

trap tt_clean_up EXIT

# Temporary files (using files because <(...) is not portable)
tt_make_temp_dir  # sets global $tt_temp_dir
set -g tt_temp_file "$tt_temp_dir/temp.txt"
set -g tt_stdin_file "$tt_temp_dir/stdin.txt"
set -g tt_test_ok_file "$tt_temp_dir/ok.txt"
set -g tt_test_output_file "$tt_temp_dir/output.txt"

# Some preparing command to run before all the tests?
if test -n "$tt_pre_command"
    eval "$tt_pre_command" ||
        tt_error "pre-flight command failed with status=$status: $tt_pre_command"
end

# For each input file in $@
for tt_test_file in $argv
    # Some tests may 'cd' to another dir, we need to get back
    # to preserve the relative paths of the input files
    cd "$tt_original_dir" ||
        tt_error "cannot enter starting directory $tt_original_dir"

    # Support using '-' to read the test file from STDIN
    if test "$tt_test_file" = '-'
        set -g tt_test_file "$tt_stdin_file"
        cat > "$tt_test_file"
    end

    # Abort when test file is a directory
    if test -d "$tt_test_file"
        tt_error "input file is a directory: $tt_test_file"
    end

    # Abort when test file not found/readable
    if test ! -r "$tt_test_file"
        tt_error "cannot read input file: $tt_test_file"
    end

    # In multifile mode, identify the current file
    if test $tt_nr_files -gt 1
        switch "$tt_output_mode"
            case normal
                # Normal mode, show message with filename
                switch "$tt_progress"
                    case test none
                        tt_message "Testing file $tt_test_file"
                    case '*'
                        test $tt_missing_nl -eq 1 && echo
                        tt_message_part "Testing file $tt_test_file "
                end
            case list list-run
                # List mode, show ------ and the filename
                tt_message (tt_separator_line | cut -c 1-40) "$tt_test_file"
        end
    end

    # Convert Windows files (CRLF) to the Unix format (LF)
    # Note: the temporary file is required, because doing "sed | while" opens
    #       a subshell and global vars won't be updated outside the loop.
    sed 's/'(printf '\r')'$//' "$tt_test_file" > "$tt_temp_file"

    # The magic happens here
    tt_process_test_file

    # Abort when no test found (and no active range with --test or --skip)
    if test $tt_nr_file_tests -eq 0 && test -z "$tt_run_range_data" && test -z "$tt_skip_range_data"
        tt_error "no test found in input file: $tt_test_file"
    end

    # Save file stats
    set -g tt_nr_file_ok (math $tt_nr_file_tests - $tt_nr_file_fails - $tt_nr_file_skips)
    set -g tt_files_stats "$tt_files_stats$tt_nr_file_ok $tt_nr_file_fails $tt_nr_file_skips$tt_nl"

    # Dots mode: any missing new line?
    # Note: had to force tt_missing_nl=0, even when it's done in tt_message :/
    test $tt_missing_nl -eq 1 && set tt_missing_nl 0 && tt_message
end

# Some clean up command to run after all the tests?
if test -n "$tt_post_command"
    eval "$tt_post_command" ||
        tt_error "post-flight command failed with status=$status: $tt_post_command"
end

#-----------------------------------------------------------------------
# From this point on, it's safe to use non-prefixed global vars
#-----------------------------------------------------------------------

# Range active, but no test matched :(
if test $tt_nr_total_tests -eq $tt_nr_total_skips
    if test -n "$tt_run_range_data" && test -n "$tt_skip_range_data"
        tt_error "no test found. The combination of -t and -s resulted in no tests."
    elif test -n "$tt_run_range_data"
        tt_error "no test found for the specified number or range '$tt_run_range'"
    elif test -n "$tt_skip_range_data"
        tt_error "no test found. Maybe '--skip $tt_skip_range' was too much?"
    end
end

# List mode has no stats
if test "$tt_output_mode" = 'list' || test "$tt_output_mode" = 'list-run'
    if test $tt_nr_total_fails -eq 0
        exit 0
    else
        exit 1
    end
end

# Show stats
#   Data:
#     $tt_files_stats -> "100 0 23 \n 12 34 0"
#     $@ -> foo.sh bar.sh
#   Output:
#          ok  fail  skip
#         100     0    23  foo.sh
#          12    34     0  bar.sh
if test $tt_nr_files -gt 1 && test "$tt_output_mode" != 'quiet'
    echo
    printf '  %5s %5s %5s\n' ok fail skip
    printf %s "$tt_files_stats" | while read ok fail skip
        printf '  %5s %5s %5s    %s\n' "$ok" "$fail" "$skip" $argv[1]
        shift
    end | sed 's/     0/     -/g'  # hide zeros
    echo
end

# The final message: OK or FAIL?
#   OK: 123 of 123 tests passed
#   OK: 100 of 123 tests passed (23 skipped)
#   FAIL: 123 of 123 tests failed
#   FAIL: 100 of 123 tests failed (23 skipped)
set skips
if test $tt_nr_total_skips -gt 0
    set skips " ($tt_nr_total_skips skipped)"
end
if test $tt_nr_total_fails -eq 0
    set stamp "{$tt_color_green}OK:{$tt_color_off}"
    set stats (math $tt_nr_total_tests - $tt_nr_total_skips)' of $tt_nr_total_tests tests passed'
    test $tt_nr_total_tests -eq 1 && set stats (echo "$stats" | sed 's/tests /test /')
    tt_message "$stamp $stats$skips"
    exit 0
else
    test $tt_nr_files -eq 1 && tt_message  # separate from previous FAILED message

    set stamp "{$tt_color_red}FAIL:{$tt_color_off}"
    set stats "$tt_nr_total_fails of $tt_nr_total_tests tests failed"
    test $tt_nr_total_tests -eq 1 && set stats (echo "$stats" | sed 's/tests /test /')
    tt_message "$stamp $stats$skips"
    # test $tt_test_file = 'test.md' && tt_message "-t ${tt_failed_range%,}"  # dev helper
    exit 1
end
