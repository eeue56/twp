#!/bin/bash
set -E
set -o functrace

function _twp::suggest_commands() {
    local flag_options cur
    flag_options="info init save quick-save drop"
    cur=$1
    COMPREPLY=( $(compgen -W "${flag_options}" -- $cur) )
}

function _twp() {
    local cur
    COMPREPLY=()
    # this is the root command, e.g compile, info
    # command_name="${COMP_WORDS[1]}"
    # this is the current word to be completed
    cur="${COMP_WORDS[COMP_CWORD]}"

    # for when we don't have a command yet
    if [[ $COMP_CWORD -eq 1 ]]; then
        _twp::suggest_commands "$cur"
        return 0
    fi

    # main command parsing
    return 1
}

function twp() {
    echo "Here we go"

    "${BASH_SOURCE%/*}/_twp_script.sh" "$@"
}

complete -F _twp "twp"