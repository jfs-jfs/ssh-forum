#!/bin/bash

### Globals
editor=""
theme=""
# new_author=""     # Declared in posting_utils

### Functions

function pick_editor()
{
    editor=$(dialog --backtitle "$banner"\
        --title "...Editor..."\
        --no-cancel\
        --menu "What do you want to use to edit your posts?"\
        10 50 2\
        "BASIC" "Normal and easy to use editor"\
        "VIM"   "The good choice"\
        3>&1 1>&2 2>&3 3>&-\
        )

    if [ -z "$editor" ]; then editor="BASIC"; fi
    # echo "$editor";read
    # editor="BASIC"
}

function pick_name()
{
    dialog\
        --max-input 20\
        --backtitle "$banner"\
        --title "...New Reply..."\
        --ok-label "CONFIRM"\
        --cancel-label "BACK"\
        --inputbox "Press <Tab> to get to the buttons.\n[AUTHOR]:"\
        10 30 "$new_author" 2>/tmp/"$usr_id" || return

    local author=$(cat /tmp/$usr_id | sed -e 's/[\"\\\;\<\>'"'"'\%]/ /g')

    if [ -z $author ]; then author="Pagan"; fi
    new_author=${author:0:20}
}

function pick_theme()
{
    theme=$(dialog --backtitle "$banner"\
        --title "...Colors..."\
        --no-cancel\
        --menu "What style do you prefer?"\
        11 50 4\
        "default"           "The classic Analog City look"\
        "nighttime"         "Dark mode, Analog City at night"\
        "monochrome"        "Like a Macintosh I"\
        "dark_slackware"    "Slackware theme pagan suggested"\
        3>&1 1>&2 2>&3 3>&-\
        )

    if [ -z "$theme" ]; then theme="default"; fi
    if [ $debug -eq 0 ]; then
        export DIALOGRC="$(pwd)/themes/$theme.dialogrc"
    else
        export DIALOGRC="/home/lowlife/shell/themes/$theme.dialogrc"
    fi
}