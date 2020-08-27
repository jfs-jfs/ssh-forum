#!/bin/bash

### Globals
new_author=""
new_title=""
content_web=""
content_ssh=""
post_size=0
abort_post=0
bump_limit=0

# Vim help
vim_file="# To exit vim press [ESC] : q [ENTER]\n# To save the file and exit [ESC] : wq [ENTER]\n# If you want to cancel the post leave this file empty(size 0)"


### Queries

# Adding posts
add_post_query_web="INSERT INTO post (author,thread_id,comment,image_link, poster_ip) VALUES ( '%s', %d, '%s', 'img', '%s');update thread set replays=replays+1 where id=%d"
add_post_query_ssh="INSERT INTO post_ssh (author,thread_id,comment,image_link, poster_ip) VALUES ( '%s', %d, '%s', 'img', '%s');update thread_ssh set replays=replays+1 where id=%d"
# Adding thread
add_thread_query_web="INSERT INTO thread (author,table_id,comment,image_link,title, poster_ip) VALUES ('%s', %d, '%s', 'img', '%s', '%s')"
add_thread_query_ssh="INSERT INTO thread_ssh (author,table_id,comment,image_link,title, poster_ip) VALUES ('%s', %d, '%s', 'img', '%s', '%s')"

## Updates
# Update n_replys
update_replys_web="UPDATE thread set replays=replays+1 where id=%d"
update_replys_ssh="UPDATE thread set replays = replays + 1 where id=%d"

### Functions
function reset_posting()
{
    new_title=""
    content_ssh=""
    content_web=""
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

    # Reset for next post
    reset_posting
}

function create_body()
{

    local free=0
    local content=""
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


    # Separate
    content_web="$(printf "$content")"
    content_ssh="$(printf "$content")"
    

    ## Prase the input
    if [ $debug -eq 0 ];
    then
        # echo -e "$bin_path./postref";read
        # Web
        content_web=$("$bin_path./postref" "$content_web")
        content_web=$("$bin_path./greentext" "$content_web")
        content_web=$("$bin_path./endline" "$content_web")

        # SSH -- TODO
        content_ssh=$($bin_path./ssh_postref "$content_ssh")
        content_ssh=$($bin_path./ssh_greentext "$content_ssh")
        content_ssh=$($bin_path./endline "$content_ssh")

    else
        # Web
        content_web=$($bin_path./postref "$content_web")
        content_web=$($bin_path./greentext "$content_web")
        content_web=$($bin_path./endline "$content_web")

        # SSH
        content_ssh=$($bin_path./ssh_postref "$content_ssh")
        content_ssh=$($bin_path./ssh_greentext "$content_ssh")
        content_ssh=$($bin_path./endline "$content_ssh")
    fi

    # Clean the double quotes and single quotes
    content_web=$(\
        printf "$content_web" | sed -e 's/\x27/\\\x27/g' -e 's/"/\\"/g'\
    )
    content_ssh=$(\
        printf "$content_ssh" | sed  -e 's/\\/\\\\/g' -e 's/\x27/\\\x27/g' -e 's/"/\\"/g'\
    )

    # printf "[ENTERING DB]:\n$content_ssh";read
}

function add_reply()
{
    # User aborted?
    if [ $abort_post -eq 1 ]; then return; fi

    ## Web
    local query=$(printf "$add_post_query_web" "$new_author" "$thread_id" "$content_web" "$ip" "$thread_id")
    other_query "$query"
    # echo -e "add rply:$query";read

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

    ## SSH
    query=$(printf "$add_post_query_ssh" "$new_author" "$thread_id" "$content_ssh" "$ip" "$thread_id")
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

    # Web
    local query=$(printf "$add_thread_query_web" "$new_author" "$board_id" "$content_web" "$new_title" "$ip")
    other_query "$query"


    if [ $query_error -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            echo "$error";echo "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your thread...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
        
        return
    fi
    reset_db

    # SSH
    query=$(printf "$add_thread_query_ssh" "$new_author" "$board_id" "$content_ssh" "$new_title" "$ip")
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