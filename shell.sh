#!/bin/bash

# Script name
s_name="$(basename $0)"

if [ "$s_name" != "shell.sh" ]; then exit; fi
if [ $# -ne 0 ]; then exit; fi

## Debug
if [ $(hostname) = "localhost" ]; then debug=1; else debug=0;fi


## Set locale for special chars
export LC_ALL=en_US.UTF-8 ## bash

## Functions and files
if [ $debug -eq 0 ];
then
    bin_path="../bin/"
    source vars.sh
    source database_utils.sh
    source browsing_utils.sh
    source posting_utils.sh
    source preference_utils.sh
else
    bin_path="/home/lowlife/bin/"
    source /home/lowlife/shell/vars.sh
    source /home/lowlife/shell/database_utils.sh
    source /home/lowlife/shell/browsing_utils.sh
    source /home/lowlife/shell/posting_utils.sh
    source /home/lowlife/shell/preference_utils.sh
fi

## Globals
DBFILE="data.db"
version="v1.2"
editor="BASIC"
usr_id="$(date +%s)analog"
day=$(date '+%d-%m-%y')
ip=$(echo $SSH_CLIENT | awk '{ print $1 }')
banner="[!]Analog City:: Interface $version[!]"
bump_limit=60
max_threads_per_day=10

# Default preferences
post_size=1024
editor="BASIC"
theme="dafault"
new_author="Pagan"
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

    while [ 0 ];
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
        --msgbox "\nWhoever you are, whom the chances of the Internet have led here, welcome. Here you will find nothing or little of what the world today appreciates. Neither the concern of being different.\n"\
        10 60
}

function get_option()
{
    option=$(\
        dialog --backtitle "$banner" \
            --title "...Decisions..."\
            --cancel-label "EXIT"\
            --menu "Please choose one option:"\
            13 80 5\
            "<Look around>"     "Surf the system."\
            "<Pick editor>"     "Pick the editor to use."\
            "<Pick nickname>"   "Default Pagan"\
            "<Pick theme>"      "Pick the theme to use."\
            "<Exit>"            "Exit the system."\
            3>&1 1>&2 2>&3 3>&-\
    )

    # echo "$option"; read
}

main

