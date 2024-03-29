#!/bin/bash

########
# Python
########

export PATH="/usr/local/opt/python@3.7/bin:$PATH"
export PATH="/usr/local/opt/python@3.7/bin/python3.7:$PATH"
export PATH="/usr/local/opt/python/libexec/bin:$PATH"

#######
# XCode
#######

function xcode-reinstall() {
    prompt_yes_no 'Are you sure you want to reinstall xcode? (y/n)'
    sudo rm -fr /Library/Developer/CommandLineTools
    xcode-select --install
}

########
# Docker
########

export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

###########
# Coreutils
###########

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

#####
# SQL
#####

# Postgres
export PATH="/usr/local/opt/libpq/bin:$PATH"

# MySql
export PATH="/usr/local/opt/mysql-client/bin:$PATH"

function sql() {
    # Usage: sql <psql|mysql> <service> [environment]
    # Define environment variables and connect to service and environment easily, example:
    #   LOCAL_MYAPP_SQL_USER
    #   LOCAL_MYAPP_SQL_PASSWORD
    #   ...
    #   <environment>_<service>_SQL_USER
    #   <environment>_<service>_SQL_PASSWORD
    #   ...
    local client="$1"
    client="$(echo "$client" | lowercase)"

    local service="$2"
    service="$(echo "$service" | uppercase)"

    echo "SERVICE: $service"

    local environment="$3"
    environment="$(echo "${environment:=LOCAL}" | uppercase)"

    echo "ENVIRONMENT: $environment"

    local     user=$(eval "echo $(printf "$%s_%s_SQL_USER"     "$environment" "$service")")
    local password=$(eval "echo $(printf "$%s_%s_SQL_PASSWORD" "$environment" "$service")")
    local     host=$(eval "echo $(printf "$%s_%s_SQL_HOST"     "$environment" "$service")")
    local     port=$(eval "echo $(printf "$%s_%s_SQL_PORT"     "$environment" "$service")")
    local database=$(eval "echo $(printf "$%s_%s_SQL_DATABASE" "$environment" "$service")")

    echo "USER: $user"
    echo "HOST: $host"
    echo "PORT: $port"
    echo "DATABASE: $database"
    echo

    if [[ -z "$user" ]]; then
        echo 'ERROR: user undefined!' > /dev/stderr
        echo 'Usage: sql <client> <service> <environment>'
        return 1
    fi

    case "$client" in
        ms|mysql)
            MYSQL_PWD="${password}" mysql \
                --user="${user}" \
                --host="${host}" \
                --port="${port}" \
                --database="${database}"
            ;;
        pg|psql|postgres)
            PGPASSWORD="${password}" psql \
                --user="${user}" \
                --host="${host}" \
                --port="${port}" \
                --dbname="${database}"
            ;;
        *)
            echo 'ERROR: Invalid client argument!' > /dev/stderr
            ;;
    esac
}

function pg_dump_table() {
    local host="$1"
    local username="$2"
    local table="$3"
    local backup="$table.$(date +%Y-%m-%d).backup"
    pg_dump --ignore-version --verbose --blobs --format=c --compress=9 --host=$host --username=$username --table=$table --file $backup
    echo $backup
}

function pg_restore_table() {
    local host="$1"
    local username="$2"
    local backup="$3"
    prompt_yes_no "Restore $backup into $username@$host? (y/n)"
    pg_restore --ignore-version --verbose --host=$host --username=$username --dbname=$username $backup
}

#########
# EXPORTS
#########

# Set timezone context
# Useful for some utilities like pytest
export TZ='US/Eastern'

# Tell the pager program less to interpret "raw" control sequences appropriately
# ie. IPython uses raw control sequences to make colored text in its displays
export PAGER=/usr/bin/less
export LESS="-R"

# Set the editor to VIM
export EDITOR=/usr/bin/vim

#######
# ALIAS
#######

alias ls="ls -lha --color=auto"
alias du="du --human-readable --max-depth=1"

# Python unittest
alias unittest="python -m unittest"

######
# MISC
######

function now() {
    date +%s
}

function bashrc() {
    $EDITOR ~/.bashrc && . ~/.bashrc
}

function uppercase() {
    cat /dev/stdin | tr '[a-z]' '[A-Z]'
}

function lowercase() {
    cat /dev/stdin | tr '[A-Z]' '[a-z]'
}

function weather() {
    # Usage: weather [city]
    if [[ $# -eq 0 ]]; then
        curl http://wttr.in/
    else
        curl "http://wttr.in/$1"
    fi
}

function line_count() {
    wc -l | tr -d '[[:space:]]'
}

function job_count() {
    jobs | line_count
}

function space() {
    # Usage: space [dir]
    # Example:
    #     space
    #     space /
    local dir="$1"
    if [[ -z "$dir" ]]; then
        dir="$PWD"
    fi
    gdu --human-readable --max-depth=1 "$dir" \
        | grep --extended-regexp 'K|M|G' \
        | sort --human-numeric-sort --reverse
}

function prompt_yes_no() {
    local message="$1"
    read -p "$message " -n 1 choice
    echo
    case "$choice" in
        y|Y)
            echo '=> Yes'
            return 0
            ;;
        n|N)
            echo '=> No'
            ;;
        *)
            echo '=> Invalid'
            ;;
    esac
    return 1
}

########
# GitHub
########

export REPOS="$HOME/repos"

function git_branch() {
    local branch
    branch="$(git symbolic-ref --short HEAD 2> /dev/null)"
    if [[ -n "$branch" ]]; then
        echo -n "$branch"
        return 0
    fi
    return 1
}

function git_name() {
    git config user.name 2> /dev/null
}

function git_has_diff() {
    git diff --quite HEAD 2> /dev/null
}

#####
# SSH
#####

function ssh_hosts() {
    grep '^Host' ~/.ssh/config | grep -v '[?*]' | cut -d ' ' -f 2-
}

# SSH auto-complete

function complete_ssh() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(ssh_hosts)
    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}

complete -F complete_ssh ssh

########
# PROMPT
########

export BLACK='\[\033[0;30m\]'
export DARK_GREY='\[\033[1;30m\]'
export LIGHT_GREY='\[\033[0;37m\]'
export BLUE='\[\033[0;34m\]'
export LIGHT_BLUE='\[\033[0;94m\]'
export LIGHT_BLUE_BOLD='\[\033[1;94m\]'
export GREEN='\[\033[0;32m\]'
export LIGHT_GREEN='\[\033[0;32m\]'
export CYAN='\[\033[0;36m\]'
export LIGHT_CYAN='\[\033[1;36m\]'
export RED='\[\033[0;31m\]'
export RED_BOLD='\[\033[1;31m\]'
export LIGHT_RED='\[\033[1;31m\]'
export PURPLE='\[\033[0;35m\]'
export LIGHT_PURPLE='\[\033[1;35m\]'
export YELLOW='\[\033[0;33m\]'
export YELLOW_BOLD='\[\033[1;33m\]'
export WHITE='\[\033[1;37m\]'
export COLOUR_OFF='\[\033[0m\]'

function title() {
    # Usage: title [window title]
    # Set the window title
    echo -ne "\033]0;$*\007"
}

function prompt_command() {
    # Set window title
    if [[ -n $SSH_CONNECTION ]]; then
        title "$HOSTNAME"
    else
        title 'localhost'
    fi
    # On pwd change, ls the directory up to N lines
    if [[ $CWD != $PWD ]]; then
        local CWD_FILES=(*)
        if [[ $CWD_FILES != '*' ]]; then
            ls -d "${CWD_FILES[@]:0:24}"
        fi
        export CWD=$PWD
    fi
    # Adjust prompt based on screen width
    local P=()
    if [[ $COLUMNS -le 80 ]]; then
        P+="[\$?] \u@\h:\w\n$ "
    else
        P+="${GREEN}↪ \$?"
        P+=" "
        P+="${PURPLE}[\t]"
        P+=" "
        P+="${WHITE}\$(git_name || echo -n \$USER)"
        P+="${GREEN}:\w"
        P+=" "
        P+="${RED_BOLD}\$(git_branch)"
        P+="${YELLOW_BOLD}\$(git_has_diff || echo -n '✗')"
        P+="${COLOUR_OFF}"
        P+="\n"
        P+="\$"
        P+=" "
    fi
    export PS1=${P[@]}
}

export PROMPT_COMMAND='prompt_command'
