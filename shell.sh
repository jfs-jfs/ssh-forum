#!/bin/bash

## Vars
version="v0.3"
banner="[!]Analog City::Posting interface $version[!]"
author="Pagan"
bye_msg="[> This is entropy, and it is taking over one bit at a time..."
### IP of the client
ip=$(echo $SSH_CLIENT | awk '{ print $1}')

## Where it is executing
case $(hostname) in

    "localhost")
    debug=1
    ;;
    *)
    debug=0
    ;;
esac

if [ $debug -eq 0 ];
then
    ip="123.123.123.132" ## DEBUG
fi

## Functions and files
if [ $debug -eq 0 ];
then
    source vars.sh
    source functions.sh
else
    source /home/lowlife/shell/vars.sh
    source /home/lowlife/shell/functions.sh
fi


##
# Menus and dialogs to make either a response or start a thread
##

function main()
{

    ### Welcome message
    welcome

    while [ 0 ];
    do
        ## Unique id
        shell="shell"
        id=$(date +%s)
        id=$id$shell


        ### Menu to pick from op or reply
        get_option

        ### Switch flow
        case $option in

            ## Creating a thread
            "<Start a thread>")
            new_thread
            ;;

            ### Replying a thread-post
            "<Reply a thread>")
            new_reply
            ;;

            ## TODO
            "<Admin Tools>")
            dialog --backtitle "$banner" \
                --title "...Identification..."\
                --no-cancel\
                --inputbox\
                "Please enter your credentials:"\
                10 50
            
            dialog --backtitle "$banner" \
                --title "...Wrong credentials..."\
                --sleep 5\
                --infobox\
                "Try again"\
                5 50
            ;;
            "<Exit>")
            clear
            echo "$bye_msg"
            exit
            ;;
        esac
    done
}

main

