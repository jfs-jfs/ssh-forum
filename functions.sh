#!/bin/bash

# Debug
if [ $(hostname) = "localhost" ]; then debug=1; else debug=0;fi

### QUERIES
board_query="SELECT id, name, description FROM board"
thread_list_query="SELECT id, title, creation, author, replays, pinned FROM thread_ssh WHERE table_id=%d ORDER BY pinned DESC, last_rp DESC LIMIT 25"
thread_query="SELECT id, author, comment, creation FROM post_ssh WHERE thread_id=%d ORDER BY creation"
thread_op_query="SELECT id, title, author, comment, creation FROM thread_ssh WHERE id=%d"
add_post_query_web="INSERT INTO post (author,thread_id,comment,image_link, poster_ip) VALUES ( '%s', %d, '%s', 'img', '%s');update thread set replays=replays+1 where id=%d"
add_post_query_ssh="INSERT INTO post_ssh (author,thread_id,comment,image_link, poster_ip) VALUES ( '%s', %d, '%s', 'img', '%s');update thread_ssh set replays=replays+1 where id=%d"
update_replys_web="UPDATE thread set replays=replays+1 where id=%d"
update_replys_ssh="UPDATE thread set replays = replays + 1 where id=%d"
add_thread_query_web="INSERT INTO thread (author,table_id,comment,image_link,title, poster_ip) VALUES ('%s', %d, '%s', 'img', '%s', '%s')"
add_thread_query_ssh="INSERT INTO thread_ssh (author,table_id,comment,image_link,title, poster_ip) VALUES ('%s', %d, '%s', 'img', '%s', '%s')"

### GLOBALS
vim_file="# To exit vim press [ESC] : q [ENTER]\n# To save the file and exit [ESC] : wq [ENTER]\n# If you want to cancel the post leave this file empty"
editor="BASIC"
version="v1.2"
banner="[!]Analog City:: Interface $version[!]"
board_id=-1
thread_id=-1
new_author="Pagan"
new_title=""
content_web=""
content_ssh=""
abort_post=0
usr_id="$(date +%s)analog"
ip=$(echo $SSH_CLIENT | awk '{ print $1}')
option=""
level=0
refresh_rate=30


### FUNCTIONS

# function fake_ctrl_c()
# {
#     sleep 0.1
#     # echo "trapped";read
# }

# trap fake_ctrl_c INT

function look_around()
{

    # echo "$level";read

    while [ "$level" -ge 0 ];
    do
        select_board
        # echo "selected borad with id $board_id";read
        select_thread
        # echo "selected thread with id $thread_id";read
        watch_thread
        # echo "watching thread with id $thread_id";read
    done

    level=0
}

function clean_tmp()
{
    rm /tmp/$usr_id
}

function select_board()
{
    if [ $level -ne 0 ]; then return; fi

    local options=()
    local title="...Pick a board..."
    local msg="Pick the board you would like to explore:"
    local backtitle=$banner
    local cmd=(\
        dialog --backtitle "$backtitle"\
        --title "$title" --cancel-label "BACK"\
        --ok-label "SELECT"\
        --menu "$msg" 13 100 5\
        )

    local boards=$(mysql -B -u$USER -p$PASS $BDNAME -e "$board_query")
    boards=$(echo -e "$boards" | tail +2)
    # echo e- "$boards"; read

    while read -r line
    do
        local id=$(echo -e "$line" | cut -d$'\t' -f1)
        local name="<$(echo -e "$line" | cut -d$'\t' -f2)>$(printf " %.0s" {0..14})";name=${name:0:14}
        local desc=$(echo -e "$line" | cut -d$'\t' -f3)
        

        # echo -e "$name $desc";sleep 0.2

        options+=("$id" "$name:: $desc")
    done <<< "$(echo -e "$boards")"

    # echo -e "${options[@]}";read

    board_id=$("${cmd[@]}" "${options[@]}" 3>&1 1>&2 2>&3 3>&-)
    
    # Check if empty
    if [ -z "$board_id" ]; then
        # echo "Cancel pressed"
        board_id=-1
        level=$(($level-1))
    else
        level=$(($level+1))
    fi

}
# select_board
# echo "$board_id"

function select_thread()
{
    if [ $board_id -eq -1 ];then return;fi  # Return to pick board
    if [ $level -ne 1 ]; then return; fi

    local options=()
    local query=$(printf "$thread_list_query" "$board_id")
    local ok_l="SELECT";
    local title="...Pick a thread..."
    local msg="Pick the board you would like to explore:"
    local backtitle=$banner
    local empty=0

    local threads=$(mysql -B -u$USER -p$PASS $BDNAME -e "$query")
    # echo -e "$query"; read
    threads=$(echo -e "$threads" | tail +2)

    if [ -n "$threads" ];then
        while read -r line
        do


            local id=$(echo -e "$line" | cut -d$'\t' -f1)
            local t_title="$(echo -e "$line" | cut -d$'\t' -f2 )$(printf ' %.0s' {0..40})";t_title=${t_title:0:40}
            local t_creation=$(echo -e "$line" | cut -d$'\t' -f3)
            local t_author="$(echo -e "$line" | cut -d$'\t' -f4)$(printf ' %.0s' {0..10})";t_author=${t_author:0:10}
            local t_replys=$(echo -e "$line" | cut -d$'\t' -f5)
            local t_pinned=$(echo -e "$line" | cut -d$'\t' -f6)


            # echo -e "$line";read;
            # echo -e "id:$id title:$t_title creation:$t_creation author:$t_author replys:$t_replys p:$t_pinned";sleep 0.2
            if [ $t_pinned -eq 1 ]; then
                options+=("$id" "$t_author:: \Z4${t_title^^}\Zn$t_creation -- $t_replys")
            else
                options+=("$id" "$t_author:: \Z5${t_title^^}\Zn$t_creation -- $t_replys")
            fi

        done <<< "$(echo -e "$threads")"
        # read

    else
        options=("Not a" "Thread in sight...")
        ok_l="BACK"
        empty=1
    fi
    # echo -e "${options[@]}";read


    local cmd=(\
            dialog --colors\
                --backtitle "$backtitle"\
                --timeout $refresh_rate\
                --cancel-label "NEW THREAD"\
                --ok-label "$ok_l"\
                --extra-button\
                --extra-label "BACK"\
                --title "$title"\
                --menu "$msg" 40 120 30\
                )

    local thread_n
    local ret=0
    "${cmd[@]}" "${options[@]}" 2>/tmp/$usr_id || ret=1
    thread_n="$(cat /tmp/$usr_id)";thread_n="$(echo $thread_n)"
    # echo "t_id:$thread_n ret:$ret empty:$empty";read

    if [ $ret -eq 0 -a $empty -eq 0 ]; then
        # echo "SELECT";read
        thread_id=$thread_n
        level=$(($level+1))
    elif [ -z "$thread_n" ]; then
        # echo "new";read
        new_thread
    elif [[ ${#thread_n} -lt 7 ]]; then
        thread_id=-1
        level=$(($level-1))
        # echo "BACK";read
    fi

    clean_tmp

}
# select_board
# select_thread

function watch_thread()
{
    if [ $board_id -eq -1 ];then return;fi
    if [ $thread_id -eq -1 ];then return;fi
    if [ $level -ne 2 ]; then return; fi

    local options=()
    local backtitle=$banner
    
    local query=$(printf "$thread_op_query" "$thread_id")
    # echo "$query";read

    # Get and format OP
    local op=$(mysql -B -u$USER -p$PASS $BDNAME -e "$query")
    op=$(echo -e "$op" | tail +2)
    # echo -e "$op"; read

    local op_id="$thread_id"
    local op_title=$(echo -e "$op" | cut -d$'\t' -f2)
    local op_author=$(echo -e "$op" | cut -d$'\t' -f3)
    local op_msg=$(echo -e "$op" | cut -d$'\t' -f4 | sed -e "s/<br>/\\\\n/g")
    local op_creation=$(echo -e "$op" | cut -d$'\t' -f5)
    # echo -e "$op_id -- $op_title -- $op_author -- $op_creation\n$op_msg"; read

    # Formatting OP
    local title="\Zr\Zb[${op_title^^}] :: [$op_author] :: [$op_creation] :: [ID:$op_id] (Scroll: j-k)\Zn"
    local body="\n$op_msg\n\n"


    # GET THE POSTS
    query=$(printf "$thread_query" "$thread_id")
    # echo "$query";read

    # Get and format POSTS
    local posts=$(mysql -B -u$USER -p$PASS $BDNAME -e "$query")
    posts=$(echo -e "$posts" | tail +2)
    # echo -e "$posts"; read

    while read -r line
    do
        local id=$(echo -e "$line" | cut -d$'\t' -f1)$(printf ' %.0s' {0..5});id=${id:0:5}
        local p_author=$(echo -e "$line" | cut -d$'\t' -f2)$(printf ' %.0s' {0..10});p_author=${p_author:0:10}
        local p_msg=$(echo -e "$line" | cut -d$'\t' -f3 | sed -e "s/<br>/\\\\n/g");
        local p_creation=$(echo -e "$line" | cut -d$'\t' -f4)
        local ln=""

        # echo -e "[EXITING DB]:\n$id $p_creation $p_author\n$p_msg";sleep 0.2
        
        ln=" \n     \Z4\Zr\Zb[ID]:$id[AUTHOR]:$p_author[CREATION]:$p_creation\Zn\n"

        body="$body$ln\n$p_msg\n\n"

    done <<< "$(echo -e "$posts")"

    # read

    dialog\
        --extra-label "REFRESH" --extra-button\
        --ok-label "BACK"\
        --cancel-label "REPLY"\
        --colors\
        --backtitle "$backtitle"\
        --title "$title"\
        --yesno "$body" 40 120

    # read
    local ret=$?
    # $ret;

    case $ret in
        0)
            # BACK
            # echo 'BACK';read
            level=$(($level-1))
            thread_id=-1
            ;;
        3)
            # REPLY
            # echo 'REFRESH';read
            # Do nothing, will reload this function
            ;;
        *)
            # REPLY
            # echo 'REPLY'; read
            create_post
        ;;
    esac

}
# select_board
# select_thread
# watch_thread

function create_post()
{
    local free=0
    local thread_n=$thread_id
    local author=""

    while [ $free -eq 0 ];
    do
        free=1
        ### Ask for thread number and other stuf
        if [ $thread_n -eq -1 ]; then
            
            dialog --backtitle "$banner"\
                    --title "...New Post Form..."\
                    --form "Please fill all the fields in the form. Switch between fields with the Arrow keys. To jump to the <OK> use the <Tab> key, also pressing <Enter> confirms the form."\
                    20 60 7\
                    "[Thread id]:"  1 13 ""                 1 27 4 3\
                    "[Author]:"     3 13 "$new_author"      3 27 20 20\
                    2>/tmp/$usr_id || return

            thread_n=$(head -n1 /tmp/$usr_id | tr -cd "[0-9]")
            thread_id=$thread_n

            # Clean author name
            new_author=$(tail -n1 /tmp/$usr_id | sed -e 's/[\"\\\;\<\>'"'"']/ /g')
            rm /tmp/$usr_id
        else

            dialog\
                --max-input 20\
                --backtitle "$banner"\
                --title "...New Reply..."\
                --ok-label "CONFIRM"\
                --cancel-label "BACK"\
                --inputbox "Press <Tab> to get to the buttons.\n[AUTHOR]:"\
                10 30 "$new_author" 2>/tmp/"$usr_id" || return

            author=$(cat /tmp/$usr_id | sed -e 's/[\"\\\;\<\>'"'"']/ /g')
            # echo "$author";read

            # new_author=$(dialog --max-input 20 --inputbox "[AUTHOR]:" 8 30 "$new_author" 3>&1 1>&2 2>&3 3>&-)
            # Clean author name
            # new_author=$(echo -e "$new_author" | sed -e 's/[\"\\\;\<\>'"'"']/ /g')

        fi


        if [ -z $author ]; then
        
            dialog --backtitle "$banner" \
                --title "...Error..."\
                --sleep 3\
                --infobox "Please fill the author field."\
                10 60
            free=0
            new_author="Pagan"
            continue
        fi

        new_author=${author:0:20}

        ## Ask if it looks okay or not
        dialog --backtitle "$banner" \
            --title "...OK?..."\
            --yesno "Does the following look good to you?

            Thread id: $thread_n
            Author: $new_author"\
            8 50 \
            || free=0
    done

    ### Create the body of the post
    touch /tmp/$usr_id
    create_body
    rm /tmp/$usr_id
    clean_tmp
    add_reply

}
# select_board
# select_thread
# watch_thread

function create_body()
{

    local free=0
    local content=""
    local ret;

    # echo "$editor";read
    echo -e "$vim_file" > /tmp/$usr_id

    while [ $free -eq 0 ];
    do
        free=1

        case "$editor" in

            "VIM")
                vim "/tmp/$usr_id"
                if [ ! -s "/tmp/$usr_id" ]; then abort_post=1; return ;fi
            ;;

            "BASIC")
                touch /tmp/$usr_id
                dialog  --backtitle "$banner" \
                    --title "...What do you have to say? (1k max.)..."\
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

        content=$(cat -s /tmp/$usr_id)
        content=${content:0:1024}

        ## Clean input  from double quotation marks, \, ;, < and double empty lines
        content=$(printf "$content" | sed -e 's/[\\\;\<]/ /g')

        if [ ${#content} -eq 0 ];
        then
            dialog --backtitle "$banner"\
                --title "...Error..."\
                --no-cancel\
                --sleep 3\
                --infobox "You can not leave this field empy."\
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
    # content_web="web"
    # content_ssh="ssh"
    content_web="$(printf "$content")"
    content_ssh="$(printf "$content")"
    

    ## Prase the input
    if [ $debug -eq 0 ];
    then
        # Web
        content_web=$(../bin/./postref "$content_web")
        content_web=$(../bin/./greentext "$content_web")
        content_web=$(../bin/./endline "$content_web")

        # SSH -- TODO
        content_ssh=$(../bin/./ssh_postref "$content_ssh")
        content_ssh=$(../bin/./ssh_greentext "$content_ssh")
        content_ssh=$(../bin/./endline "$content_ssh")

    else
        # Web
        content_web=$(/home/lowlife/bin/./postref "$content_web")
        content_web=$(/home/lowlife/bin/./greentext "$content_web")
        content_web=$(/home/lowlife/bin/./endline "$content_web")

        # SSH
        content_ssh=$(/home/lowlife/bin/./ssh_postref "$content_ssh")
        content_ssh=$(/home/lowlife/bin/./ssh_greentext "$content_ssh")
        content_ssh=$(/home/lowlife/bin/./endline "$content_ssh")
    fi

    # Clean the double quotes and single quotes
    content_web=$(\
        printf "$content_web" | sed -e 's/\x27/\\\x27/g' -e 's/"/\\"/g'\
    )
    content_ssh=$(\
        printf "$content_ssh" | sed  -e 's/\\/\\\\/g' -e 's/\x27/\\\x27/g' -e 's/"/\\"/g'\
    )

    # printf "[ENTERING DB]:\n$content_ssh";read

    clean_tmp
}

function add_reply()
{
    # User aborted?
    if [ $abort_post -eq 1 ]; then
        abort_post=0
        return
    fi

    # Web
    local query=$(printf "$add_post_query_web" "$new_author" "$thread_id" "$content_web" "$ip" "$thread_id")
    mysql -u$USER -p$PASS $BDNAME -e "$query"

    if [ $? -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            read;printf "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your post...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
            return;
    fi

    # SSH
    query=$(printf "$add_post_query_ssh" "$new_author" "$thread_id" "$content_ssh" "$ip" "$thread_id")
    mysql -u$USER -p$PASS $BDNAME -e "$query"

    if [ $? -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            read;printf "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your post...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
            return;
    fi

    # Cleaning
    content_web=""
    content_ssh=""

    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "SUCCESS."\
            8 60
}


function new_thread()
{
    if [ $board_id -eq -1 ]; then
        select_board
    fi

    # Pressed cancel on select board
    if [ "$board_id" -eq -1 ];
    then
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

        new_title=$(head -n1 /tmp/$usr_id | sed -e 's/[\"\\\;\<\>]/ /g' -e 's/'"'"'/'"\\'"'/g')
        new_author=$(tail -n1 /tmp/$usr_id | sed -e 's/[\"\\\;\<\>'"'"']/ /g')
        rm /tmp/$usr_id

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
    rm /tmp/$usr_id
    add_thread

    clean_tmp
}


function add_thread()
{
    # User aborted?
    if [ $abort_post -eq 1 ]; then
        abort_post=0;
        return
    fi

    # Web
    local query=$(printf "$add_thread_query_web" "$new_author" "$board_id" "$content_web" "$new_title" "$ip")
    mysql -u$USER -p$PASS $BDNAME -e "$query"


    if [ $? -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            echo "$error";echo "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your thread...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
        
        return
    fi

    # SSH
    query=$(printf "$add_thread_query_ssh" "$new_author" "$board_id" "$content_ssh" "$new_title" "$ip")
    mysql -u$USER -p$PASS $BDNAME -e "$query"


    if [ $? -eq 1 ]; then

        if [ $debug -eq 0 ]; then
            echo "$query";exit
        fi

        dialog --backtitle "$banner" \
            --title "...Error..."\
            --msgbox "Something went wrong when commiting your thread...Please report it at https://github.com/analogcity/shell. Thanks!"\
            10 60
        
        return
    fi

    # Cleaning
    content_web=""
    content_ssh=""
    new_title=""

    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "SUCCESS."\
            8 60

}

function welcome()
{
    dialog --backtitle "$banner" \
        --title "...Welcome..."\
        --msgbox "\nWhoever you are, whom the chances of the Internet have led here, welcome. Here you will find nothing or little of what the world today appreciates. Neither the concern of being different.\n"\
        10 60
}

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

function get_option()
{
    option=$(\
        dialog --backtitle "$banner" \
            --title "...Decisions..."\
            --cancel-label "EXIT"\
            --menu "Please choose one option:"\
            12 80 4\
            "<Look around>"     "Surf the system."\
            "<Pick editor>"     "Pick the editor to use."\
            "<Exit>"            "Exit the system."\
            3>&1 1>&2 2>&3 3>&-\
    )

    # echo "$option"; read
}