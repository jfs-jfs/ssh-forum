#!/bin/bash

# Script name
s_name="$(basename "$0")"

if [ "$s_name" != "shell.sh" ]; then exit; fi
if [ $# -ne 0 ]; then exit; fi

## Debug
if [ "$(hostname)" = "localhost" ]; then debug=1; else debug=0;fi

# Import configuration
source config.sh

## Set locale for special chars
export LC_ALL=en_US.UTF-8 ## bash

## Functions and files
if [ $debug -eq 0 ];
then
    bin_path="bin/"
    DBFILE="data.db"
    source database_utils.sh
    source browsing_utils.sh
    source posting_utils.sh
    source preference_utils.sh
    source chat_utils.sh
else
    bin_path="/home/$USER/shell/bin/"
    DBFILE="/home/$USER/shell/data.db"
    source /home/$USER/shell/database_utils.sh
    source /home/$USER/shell/browsing_utils.sh
    source /home/$USER/shell/posting_utils.sh
    source /home/$USER/shell/preference_utils.sh
    source /home/$USER/shell/chat_utils.sh
fi

## Globals
version="$VERSION"
usr_id="$(date +%s)analog"
day=$(date '+%d-%m-%y')
ip=$(echo "$SSH_CLIENT" | awk '{ print $1 }')
banner="[!]$BANNER ${version}[!]"
bump_limit=$BUMP_LIMIT
max_threads_per_day=$THREADS_X_DAY

# Default preferences
post_size=$POST_SIZE
editor="$EDITOR"
theme="$THEME"
new_author="$AUTHOR_NAME"
new_title=""


if [ $debug -eq 0 ];
then
    ip="123.123.123.132" ## DEBUG
fi


function main()
{

    ### Welcome message
    welcome
    # read

    while true;
    do

        ### Menu to pick from op or reply
        get_option
        # echo "$option";read

        ### Switch flow
        case $option in

            ## Creating a thread
            "<Look around>")
            look_around
            # read
            ;;

            "<Pick editor>")
            pick_editor
            # read
            ;;

            "<Pick nickname>")
            pick_name
            # read
            ;;

            "<Pick theme>")
            pick_theme
            # read
            ;;

            "<Chat>")
            start_chat
            # read
            ;;

            *)
            clear
            exit
            ;;
        esac

        # Update ID
        usr_id="$(date +%s)analog"

    done
}

function welcome()
{
    dialog --backtitle "$banner" \
        --title "...Welcome..."\
        --msgbox "\n$WELCOME_MSG\n"\
        10 60
}

function get_option()
{
    option=$(\
        dialog --backtitle "$banner" \
            --title "...Decisions..."\
            --cancel-label "EXIT"\
            --menu "Please choose one option:"\
            13 80 6\
            "<Look around>"     "Surf the system."\
            "<Chat>"            "Real time chat."\
            "<Pick editor>"     "Pick the editor to use."\
            "<Pick nickname>"   "Default Pagan"\
            "<Pick theme>"      "Pick the theme to use."\
            "<Exit>"            "Exit the system."\
            3>&1 1>&2 2>&3 3>&-\
    )

    # echo "$option"; read
}

main

