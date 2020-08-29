#!/usr/bin/env fish

# ./doctest.fish test.txt
# find ../fish-shell/sphinx_doc_src -name "*.rst" | while read file; ./doctest.fish -q $file; end

# Defaults
set prefix '    '
set prompt '>_ '
set debug_level 0
set quiet_level 0

# Parse command line arguments
argparse 'q/quiet' 'd-debug' 'x-prefix=' 'p-prompt=' -- $argv; or exit 1
set quiet_level (count $_flag_quiet)
set debug_level (count $_flag_debug)
set -q _flag_prefix; and set prefix $_flag_prefix
set -q _flag_prompt; and set prompt $_flag_prompt
set input_file $argv[1]

# ^ We support only one single input file, because handling multiple
# have scope problems. All tests are executed with eval in the same
# scope, so variables defined in one test will be available for the next
# ones. This is expected for all the tests in a single file. But having
# variables from one test file affecting the tests in another test file
# is unexpected. We avoid that by only testing one file per call.

# This will be the main identifier for commands
set command_id $prefix$prompt
set command_id_trimmed (string replace --regex ' $' '' -- $command_id)

# Pre-compute lengths to be used inside the main loop
set prefix_length (string length -- $prefix)
set command_id_length (string length -- $command_id)

# Commands prefixed with this will be skipped. This is automatically
# added to unsupported commands.
set skip_prefix '#SKIP '

function echo_color # color message
    set_color $argv[1]
    printf '%s\n' $argv[2..-1]
    set_color normal
end

function debug # color message
    test $debug_level -gt 0; and echo_color $argv
end

function error # message
    echo_color red (basename (status -f))": Error: $argv"
    exit 1
end

function validate_input_file -a path
    test -n "$path"; or error 'no test file informed'
    test -d "$path"; and error "input file is a directory: $path"
    test -r "$path"; or error "cannot read input file: $path"
end

function starts_with -a pattern string
    test -z "$pattern"; and return 0 # empty pattern always matches
    test -z "$string"; and return 1 # empty string never matches
    set -l string_prefix (string sub -l (string length -- $pattern) -- $string)
    test "$string_prefix" = "$pattern"
end

function show_diff # expected output
    diff -u (printf '%s\n' $expected | psub) (printf '%s\n' $output | psub) |
    sed '1 { /^--- / { N; /\n+++ /d; }; }' # no ---/+++ headers
end

function handle_unsupported_commands -a cmd
    # 1. set -l
    #    When using `eval set -l foo`, the variable $foo is not
    #    available for the next tests. When removing `-l` it works.
    # 2. commandline
    #    The following error is shown whe trying to eval it
    #    "Can not set commandline in non-interactive mode"

    if starts_with 'set -l ' $cmd # 1
        string replace --regex \
            '^set -l (.*)' \
            'set $1  #[set -l not supported]' \
            -- $cmd
    else if starts_with 'commandline ' $cmd; or starts_with 'commandline' $cmd # 2
        string replace --regex \
            '^(commandline.*)' \
            $skip_prefix'$1  #[commandline not supported]' \
            -- $cmd
    else
        echo -- $cmd
    end
end

validate_input_file $input_file

set line_number 0
set test_number 0
set total_failed 0
set total_skipped 0

# Adding extra empty line to the end to make the algorithm simpler. Then
# we always have a last-line trigger for the last pending command.
# Otherwise we would have to handle the last command after the loop.
for line in (cat $input_file) ''

    set line_number (math $line_number + 1)
    set run_test 0

    debug yellow "Line $line_number: [$line]"

    if starts_with $command_id $line
        # Found a command line

        set next_command (string sub -s (math $command_id_length + 1) -- $line)
        set next_command (handle_unsupported_commands $next_command)

        debug blue "Line $line_number: COMMAND [$next_command]"

        if set -q current_command
            set run_test 1
        else
            set current_command $next_command
            set --erase next_command
        end

    else if test "$line" = "$command_id" || test "$line" = "$command_id_trimmed"
        # Line has prompt, but it is an empty command

        set -q current_command && set run_test 1

    else if test -n "$current_command$next_command" && starts_with $prefix $line
        # Line has the prefix and is not a command, so this is the
        # command output

        set output_line (string sub -s (math $prefix_length + 1) -- $line)
        set --append current_output $output_line

        debug cyan "Line $line_number: OUTPUT [$output_line]"

    else
        # Line is not a command neither command output

        set -q current_command && set run_test 1

        debug magenta "Line $line_number: OTHER [$line]"
    end


    # Run the current test
    if test $run_test -eq 1
        set test_number (math $test_number + 1)

        set -l test_description "[$test_number] $current_command"
        set -l expected $current_output
        set -l output (eval $current_command 2>&1)

        # ^ Here (eval) is where the command is really executed.
        # Note: eval cannot be inside a function due to scope rules. A
        #       defined foo var should be accessible by the next tests.

        if starts_with $skip_prefix $current_command
            # SKIP
            set total_skipped (math $total_skipped + 1)
            test $quiet_level -eq 0; and echo_color cyan $test_description

        else if test "$output" = "$expected"
            # OK
            test $quiet_level -eq 0; and echo_color green $test_description

        else
            # FAIL
            set total_failed (math $total_failed + 1)
            if test $quiet_level -le 1
                echo_color red $test_description
                show_diff (string collect -- $expected) (string collect -- $output)
            end
        end

        set --erase current_command
        set --erase current_output

        if set -q next_command
            set current_command $next_command
            set --erase next_command
        end
    end
end

if test $test_number -eq 0
    echo "$input_file: No tests found"
else
    test $quiet_level -eq 0; and echo
    test $quiet_level -le 1
    and printf '%s: Tested %d commands (%d failed, %d skipped)\n' \
        $input_file $test_number $total_failed $total_skipped
end

# Script exit code will be zero only when there are no failed tests
test $total_failed -eq 0


# - line: 1
#   command: "string match '?' a"
# - line: 2
#   output:
#     - "a"
#     - "b"

# - line: 1
#   type: command
#   content: "string match '?' a"
# - line: 2
#   type: output
#   content:
#     - "a"
#     - "b"

# XXX json.fish - nao faz sentido ter um generico, pois o fish nao tem dicionários nem pode aninhar listas
# só se fosse um "string escape --style=json $content" que eu podia contribuir upstream
# só se fosse um "string escape --style=yaml $content" que eu podia contribuir upstream
#
# [
#   {
#     "line": 1,
#     "type": "command",
#     "content": "string match '?' a"
#   },
#   {
#     "line": 2,
#     "type": "output",
#     "content": [
#       "a",
#       "b"
#     ]
#   }
# ]

# command(22, "string match 'foo?' 'foo1' 'foo' 'foo2'")
# output(23, "foo1")

# será ruim de remover as aspas na hora de usar o 3o argumento
# 22 command "string match 'foo?' 'foo1' 'foo' 'foo2'"
# 23 output "foo1"

# nao rola :(
# $ echo $cmd
# string match 'foo?' "foo1" 'foo' 'foo2'
# $ string escape --style=script -n $cmd
# string\ match\ \'foo\?\'\ \"foo1\"\ \'foo\'\ \'foo2\'
#
# teria que ser algo como
# $ string escape --style=script -n $cmd
# "string match 'foo?' \"foo1\" 'foo' 'foo2'"
#
# talvez desistir da ideia de primeiro parsear e depois rodar o teste?
# porque no momento do parsing eu tenho o comando na mão, prontinho
# agora, será complicado comverter ele pra texto (json, yaml) whatever
# e depois colocar esse texo de forma que o eval receba ele inalterado
#
# o que posso fazer é um --dump que pula o eval e faz o dump do txt/json
#
# problema que não posso mostrar o resultado dos testes com junit, que
# envolve um header com somatórias dos testes. talvez seja tudo bem ser
# assim pra deixar tudo mais simples. um script pequeno, funcional,
# barebones. ele pode evoluir se for o caso, no futuro.

# command 1 "..."
# output 2 "..."
# XXX como ficam os escapes tipo \" \t? (o parser deve extrair as linhas exatmente, sem alteracoes)
