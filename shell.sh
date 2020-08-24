#!/bin/bash

## Set locale for special chars
export LC_ALL=en_US.UTF-8 ## bash

# Debug
if [ $(hostname) = "localhost" ]; then debug=1; else debug=0;fi

## Functions and files
if [ $debug -eq 0 ];
then
    source vars.sh
    source functions.sh
else
    source /home/lowlife/shell/vars.sh
    source /home/lowlife/shell/functions.sh
fi

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
            *)
            clear
            exit
            ;;
        esac

        # Update ID
        usr_id="$(date +%s)analog"

    done
}

main

