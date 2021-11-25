#!/bin/bash

### Globals
new_author=""
new_title=""
content=""
post_size=0
abort_post=0
bump_limit=0
max_threads_per_day=10

# Vim help
vim_file="# To exit vim press [ESC] : q [ENTER]\n# To save the file and exit [ESC] : wq [ENTER]\n# If you want to cancel the post leave this file empty(size 0)"


### Queries

# Adding posts
add_post_query="INSERT INTO post (author,thread_id,body,author_ip) VALUES ( '%s', %d, '%s', '%s')"
# Adding thread
add_thread_query="INSERT INTO thread (author,board_id,body,title,author_ip) VALUES ('%s', %d, '%s', '%s', '%s')"

### Functions
function reset_posting()
{
    new_title=""
    content=""
    abort_post=0
}

function new_reply()
{
    if [ $thread_id -eq -1 ]; then
        echo "Cant post reply whitout thread id";read
        return
    fi

    # Create the body
    touch /tmp/$usr_id
    create_body
    add_reply

    # Reset for next post
    reset_posting
}


function new_thread()
{
    if [ $board_id -eq -1 ]; then
        echo "Needs a board to make a thread"; read
        return
    fi

    # Check we can post
    if [ -f "/tmp/$day" ]; then

        local threads_today=$(wc -m "/tmp/$day" | cut -d' ' -f1)

        if [ $threads_today -ge $max_threads_per_day ]; then
                dialog --backtitle "$banner" \
                    --title "[!]Max threads[!]"\
                    --msgbox "\nSorry but the max number of threads per day($max_threads_per_day) has been exceded. If it seems to low please post in suggestions. Sorry!"\
                    10 60
            return
        fi

    else
        touch "/tmp/$day"
    fi

    local free=0

    while [ $free -eq 0 ];
    do
        free=1

        ## Fill up the form
        dialog --backtitle "$banner"\
            --title "...New Thread Form..."\
            --form "Please fill all the fields in the form. Switch between fields with the Arrow keys. To jump to the <OK> use the <Tab> key, also pressing <Enter> confirms the form.\n"\
            20 60 6\
            "[Title]:"  2 15 "$new_title"      2 27 20 100\
            "[Author]:" 4 15 "$new_author"     4 27 20 20\
            2>/tmp/$usr_id || return

        # TODO: fix this mess
        new_title=$(head -n1 /tmp/$usr_id | sed -e 's/[\"\\\;\<\>\%]/ /g' -e 's/'"'"'/'"\\'"'/g')
        new_author=$(tail -n1 /tmp/$usr_id | sed -e 's/[\"\\\;\<\>'"'"'\%]/ /g')

        ## Check for empty field
        if [ -z $new_title ];
        then
            dialog --backtitle "$banner" \
                --title "...Error..."\
                --sleep 3\
                --infobox "Please fill the title field."\
                10 60
            free=0
            continue
        fi

        if [ -z $new_author ];
        then
            dialog --backtitle "$banner" \
                --title "...Error..."\
                --sleep 3\
                --infobox "Please fill the author field."\
                10 60
            free=0
            new_author="Pagan"
            continue
        fi

        ## Ask if it looks okay or not
        dialog --backtitle "$banner" \
            --title "...OK?..."\
            --yesno "Does the following look good to you?

            Title: $new_title
            Author: $new_author"\
            8 50 \
            || free=0
    done

    ### Create the body of the post
    touch /tmp/$usr_id
    create_body
    add_thread

    ### Count created thread
    echo 'x' >> "/tmp/$day"

    # Reset for next post
    reset_posting
}

function create_body()
{

    local free=0
    local ret;

    # echo "$editor";read
    
    # Done here so the user that uses vim can preserve the contents
    # of his post if he wants to modify
    echo -e "$vim_file" > /tmp/$usr_id

    while [ $free -eq 0 ];
    do
        free=1

        case "$editor" in

            "VIM")

                # echo "VIM"; read
                if [ $debug -eq 0 ]; then
                    .././vim -Z -n "/tmp/$usr_id"
                else
                    /home/lowlife/shell/./vim -Z -n "/tmp/$usr_id"
                fi
                # read;

                # If file size = 0 means cancel
                if [ ! -s "/tmp/$usr_id" ]; then abort_post=1; return ;fi
            ;;

            "BASIC")
                # Clean vim comments
                touch /tmp/$usr_id

                # Display editor
                dialog  --backtitle "$banner" \
                    --title "...What do you have to say? ($post_sizeb max.)..."\
                    --cancel-label "BACK"\
                    --ok-label "CONFIRM"\
                    --max-input 1024\
                    --editbox /tmp/$usr_id \
                    20 120 2>/tmp/$usr_id

                ret=$?
                # Go back
                if [ $ret -eq 1 ]; then
                    # Setting abort flag
                    abort_post=1;
                    # echo "abort:$abort_post"; read
                    return;
                fi
            ;;

            *)
                echo "FUCKED UP";exit
            ;;

        esac

        # Delete the % sign causes wierd stuff to happen LOOK INTO IT
        # Delete multiple empty lines
        content=$(cat -s /tmp/$usr_id | sed -e 's/\%/ /g')

        # Post size restrictions
        content=${content:0:$post_size}

        # TODO: fix this mess
        # Clean input  from double quotation marks, \, ;, < and double empty lines
        content=$(printf "$content" | sed -e 's/[\\\;\<]/ /g' -e '/^# /d')
        # echo "$content ${#content}";read

        if [ ${#content} -eq 0 ];
        then
            dialog --backtitle "$banner"\
                --title "...Error..."\
                --no-cancel\
                --sleep 3\
                --infobox "You can not leave this field empty."\
                10 60
                free=0
                continue
        fi

        dialog --backtitle "$banner" \
            --title "...OK?..."\
            --yesno "Does the following look good to you?\n$content"\
            20 120 \
            || free=0

    done

    ## Prase the input
    content=$($bin_path./postref "$content")
    content=$($bin_path./greentext "$content")
    content=$($bin_path./endline "$content")

    # Clean the double quotes and single quotes
    content=$(\
        printf "$content" | sed  -e 's/\\/\\\\/g' -e 's/\x27/\\\x27/g' -e 's/"/\\"/g'\
    )

    # printf "[ENTERING DB]:\n$content";read
}

function add_reply()
{
    # User aborted?
    if [ $abort_post -eq 1 ]; then return; fi

    ## SSH
    query=$(printf "$add_post_query" "$new_author" "$thread_id" "$content" "$ip")
    # echo "$query" ; read
    other_query "$query"

    if [ $query_error -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            read;printf "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your post...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
            return;
    fi
    reset_db

    # Feed back to user
    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "SUCCESS."\
            8 60
}


function add_thread()
{
    # User aborted?
    if [ $abort_post -eq 1 ]; then return; fi

    # SSH
    query=$(printf "$add_thread_query" "$new_author" "$board_id" "$content" "$new_title" "$ip")
    other_query "$query"


    if [ $query_error -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            echo "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your thread...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
        
        return
    fi
    reset_db

    # Feed back to user
    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "SUCCESS."\
            8 60

}