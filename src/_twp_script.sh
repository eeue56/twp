#!/bin/bash
set -o functrace

function _twp::hide_cursor {
    tput civis
}

function _twp::restore_cursor {
    tput cnorm
}

function _twp::highlight_text {
    tput smso
    echo -n "$1"
    tput rmso
}

function _twp::delete_last_x_lines() {
    local amount_of_lines_to_delete=$1
    for _ in $(seq "$amount_of_lines_to_delete"); do
        tput cuu1
        tput el
    done
}

function _twp::handle_error {
    local retval=$?
    local line=${last_lineno:-$1}
    echo "Failed at $line: $BASH_COMMAND"
    _twp::restore_cursor
    trap - ERR
    trap - SIGINT
    trap - EXIT
    exit $retval
}

function _twp::handle_ctrl_c () {
    echo "exiting..."
    _twp::restore_cursor
    trap - SIGINT            # Restore signal handling for SIGINT.
    trap - ERR
    trap - SIGINT
    trap - EXIT
    exit 1                   #   then exit script.
}

function _twp::handle_exit () {
    _twp::restore_cursor
    trap - EXIT
    trap - ERR
    trap - SIGINT
    trap - EXIT
    exit 1
}

trap '_twp::handle_error $LINENO ${BASH_LINENO[@]}' ERR
trap '_twp::handle_ctrl_c' SIGINT
trap _twp::handle_exit EXIT

function _twp::apply_no_space() {
    type compopt &>/dev/null && compopt -o nospace
}

function _twp::get_root_directory() {
    git rev-parse --show-toplevel
}

function _twp::init() {
    remote_url=$1

    git clone "$remote_url"
}

function _twp::info() {
    remote=$(git remote get-url origin)

    hostname=$(echo "$remote" | grep -o -P "@(.+):" | tail -c +2 | head -c -2)
    echo "Hostname: $hostname"

    remote_repo=$(echo "$remote" | grep -o -P ":(.+)\." | tail -c +2 | head -c -2)
    echo "Repo: $remote_repo"

    git status
}

function _twp::_mark_files() {
    local prompt="$1"
    local options
    IFS=" " read -r -a options <<< "$2"
    local cur=0
    local count=${#options[@]}
    local index=0
    declare -A marked_files
    for option in "${options[@]}"; do
        marked_files["$option"]=false
    done

    printf "%s\n" "$prompt"
    _twp::hide_cursor

    while true; do
        index=0
        for option in "${options[@]}"; do
            local is_marked
            is_marked=${marked_files[$option]}

            local prefix

            if [ "$is_marked" = true ]; then
                prefix="[x]"
            else
                prefix="[ ]"
            fi;

            if [ "$index" = "$cur" ]; then
                echo -n "$prefix > "
                # _twp::highlight_text "\e[7m$option\e[0m" # mark & highlight the current option
                _twp::highlight_text "$option" # mark & highlight the current option
                echo
            else
                echo "$prefix   $option"
            fi
            index=$((index + 1))
        done
        echo "Press Enter to add them to .gitignore"
        local lines_to_re_render=$((count + 1))

        IFS= read -r -s -n1 key # wait for user to key in arrows or ENTER
        if [[ $key == $'\x1b' ]]; then
            read -rsn1 -t 0.01 key
            read -rsn1 -t 0.01 key

            if [[ $key == $'A' ]]; then # up arrow
                cur=$((cur - 1))
                if [ "$cur" -lt 0 ]; then
                    cur=0
                fi
            elif [[ $key == $'B' ]]; then # down arrow
                cur=$((cur + 1))
                if [ $cur -ge "$count" ]; then
                    cur=$(( count - 1 ))
                fi
            fi
        elif [[ "$key" == " " ]]; then
            local current_option
            current_option=${options[$cur]}

            if [ "${marked_files[$current_option]}" = true ]; then
                marked_files[$current_option]=false
            else
                marked_files[$current_option]=true
            fi
        elif [[ $key == "" ]]; then # nothing, i.e the read delimiter - ENTER
            break
        fi

        _twp::delete_last_x_lines $lines_to_re_render
        # echo -en "\e[${lines_to_re_render}A" # go up to the beginning to re-render
    done

    local marked=()


    for file_name in "${!marked_files[@]}"; do
        local is_marked=${marked_files[$file_name]}

        if [ "$is_marked" = true ]; then
            marked+=("$file_name")
        fi
    done

    _twp::restore_cursor
    declare -ag RET_VAL=("${marked[@]}")
}

function _twp::_untracked_files() {
    git ls-files --other --exclude-standard | tr " " "\n"
}

function _twp::_untracked_dirs() {
    git ls-files --other --directory --exclude-standard | tr " " "\n"
}

function _twp::_untracked_dotfiles() {
    git ls-files --other --exclude-standard | tr " " "\n" | grep -o -P "^\..+"
}

function _twp::_has_untracked_gitignore() {
    if [[ $( _twp::_untracked_dotfiles | grep -o -P "^\.gitignore$" | wc -l ) = 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function _twp::_ask_confirmation() {
    declare -g CONFIRM
    local prompt=$1

    echo "$prompt"

    local response
    read -r -s -n1 response

    if [[ "$response" = "y" || "$response" = "Y" || "$response" = "" ]]; then
        CONFIRM="true"
    else
        CONFIRM="false"
    fi
}

function _twp::_ask_to_add_gitignore() {
    local prompt="Found a .gitignore file in the root, but it wasn't added to git yet.\nAdd it? [Y]/n"

    _twp::_ask_confirmation "$prompt"
}

function _twp::_mark_files_to_add_to_gitignore() {
    local files_that_probably_shouldnt_be_added="$1"
    local prompt="These files appear to be dotfiles. Choose which ones to add to .gitignore:"

    echo "$files_that_probably_shouldnt_be_added"
    _twp::_mark_files "$prompt" "$files_that_probably_shouldnt_be_added"
}

function _twp::interactive_add_untracked() {
    local git_root
    git_root=$(_twp::get_root_directory)

    local untracked_dirs
    untracked_dirs=$(_twp::_untracked_dirs)

    # flag dot files for exclusion
    local files_that_probably_shouldnt_be_added
    files_that_probably_shouldnt_be_added=$( _twp::_untracked_dotfiles | tr "\n" " " )

    local should_add_gitignore=false

    if [[ $( _twp::_has_untracked_gitignore ) = "true" ]]; then
        _twp::_ask_to_add_gitignore

        if [[ $CONFIRM = "true" ]]; then
            git add --intent-to-add "$git_root/.gitignore"
            # rescan since now .gitignore should be excluded
            files_that_probably_shouldnt_be_added=$( _twp::_untracked_dotfiles | tr "\n" " " )
            echo "Added!"
        else
            echo "Skipping, I recommend that you add it though."
        fi
    fi

    local files_to_add_to_gitignore

    if [[ -n $files_that_probably_shouldnt_be_added ]]; then
        _twp::_mark_files_to_add_to_gitignore "$files_that_probably_shouldnt_be_added"
        files_to_add_to_gitignore=("${RET_VAL[@]}")

        echo "Adding ${#files_to_add_to_gitignore[@]} files to .gitignore..."

        for file in "${files_to_add_to_gitignore[@]}"; do
            echo "$file" >> "$git_root/.gitignore"
            echo "Added $file..."
        done

        echo "Done!"
    fi

    local files_that_probably_shouldnt_be_added_array
    files_that_probably_shouldnt_be_added_array=("${files_that_probably_shouldnt_be_added[@]}")

    # if:
    # - there were files added
    ##- git ignore was added
    if [[ "${#files_to_add_to_gitignore[@]}" -ne "${#files_that_probably_shouldnt_be_added_array[@]}" || $should_add_gitignore = true ]]; then
        local seperate_gitignore_commit

        echo ".gitignore related changes:"

        echo "Create separate commit for .gitignore changes? [Y]/n"
        read -s -r -n1 seperate_gitignore_commit

        local should_have_a_separate_gitignore_commit=false

        if [[ "$seperate_gitignore_commit" = "y" || "$seperate_gitignore_commit" = "Y" || "$seperate_gitignore_commit" = "" ]]; then
            should_have_a_separate_gitignore_commit=true
        fi

        if [[ $should_have_a_separate_gitignore_commit = true ]]; then
            local files_to_save
            files_to_save=("${files[@]}")
            if [[ $should_add_gitignore = true ]]; then
                files_to_save+=(".gitignore")
            fi

            git commit -m "add files to gitignore" "${files_to_save[@]}"
        fi
    fi
}

function _twp::save() {
    untracked_dirs=$(git ls-files --other --directory --exclude-standard)

    if [[ -n "$untracked_dirs" ]]; then
        echo "there are untracked dirs $untracked_dirs"
    fi

    _twp::interactive_add_untracked

    echo "Starting interactive save..."

    git commit -p
}

function _example() {
    echo "$1"
    echo "$2"
}

function twp() {
    local command_name
    command_name=$1

    if [[ $command_name == "info" ]]; then
        _twp::info
    elif [[ $command_name == "init" ]]; then
        _twp::init "$2"
    elif [[ $command_name == "save" ]]; then
        _twp::save
    elif [[ $command_name == "_test" ]]; then
        $2
    elif [[ $command_name == "_test_interactive" ]]; then
        $2 "${@:4}"
        local var=$3
        echo "${!var}"
    fi
}

twp "$@"