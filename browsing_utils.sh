#!/bin/bash

### Globals
level=0             # Control where is the user
board_id=-1         # Board to display
thread_id=-1        # Thread to display
queried_boards=1    # Do not oversaturate the database
boards=()           # Boards to pick from
max_iterations=500  # Break if something goes wrong

# Vim help
vim_file="# To exit vim press [ESC] : q [ENTER]\n# To save the file and exit [ESC] : wq [ENTER]\n# If you want to cancel the post leave this file empty(size 0)"


# If query fails
error_msg="Something went wrong. If persists report it to github.com/analogcity\nPres enter to continue...";

### Queries

# Board related
board_query="SELECT id, name, description FROM board"
thread_list_query="SELECT id, title, creation, author, replays, pinned FROM thread_ssh WHERE table_id=%d ORDER BY pinned DESC, last_rp DESC LIMIT 25"

# Thread related
thread_query="SELECT id, author, comment, creation FROM post_ssh WHERE thread_id=%d ORDER BY creation"
thread_op_query="SELECT id, title, author, comment, creation FROM thread_ssh WHERE id=%d"

### Functions

function look_around()
{

    # echo "$level";read

    while [ $level -ge 0  -a $max_iterations -ge 0 ];
    do
        # LVL 0
        select_board
        # echo "selected borad with id $board_id";read
        # LVL 1
        select_thread
        # echo "selected thread with id $thread_id";read
        # LVL 2
        watch_thread
        # echo "watching thread with id $thread_id";read

        # Fail safe
        max_iterations=$(($max_iterations-1))
    done

    level=0
}


function select_board()
{
    if [ $level -ne 0 ]; then return; fi    # This is level 0

    # Dialog parameters
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

    if [ $queried_boards -eq 1 ]; then
        # Look it up the database
        select_query "$board_query"
        local res="$(echo -e "$query_result" | tail -n+2 )"
        # echo -e "$query_result"; read
        reset_db

        # Prase database output
        while read -r line
        do
            local id=$(echo -e "$line" | cut -d$'\t' -f1)
            local name="<$(echo -e "$line" | cut -d$'\t' -f2)>$(printf " %.0s" {0..14})";name=${name:0:14}
            local desc=$(echo -e "$line" | cut -d$'\t' -f3)

            options+=("$id" "$name:: $desc")

            # echo -e "$name $desc";sleep 0.2
        done <<< "$(echo -e "$res")"

        boards=( "${options[@]}" )
        queried_boards=0
    fi


    # echo -e "${boards[@]}";read

    # Display dialog
    board_id=$("${cmd[@]}" "${boards[@]}" 3>&1 1>&2 2>&3 3>&-)
    
    # Check if empty
    if [ -z "$board_id" ]; then
        # echo "Cancel pressed"
        board_id=-1
        level=$(($level-1))
    else
        level=$(($level+1))
    fi

}

function select_thread()
{
    if [ $board_id -eq -1 ];then return;fi  # Return to pick board
    if [ $level -ne 1 ]; then return; fi    # This is level 1

    # Dialog parameters
    local backtitle=$banner
    local title="...Pick a thread..."
    local msg="Pick the board you would like to explore:"
    local ok_l="SELECT";
    local options=()

    local query=$(printf "$thread_list_query" "$board_id")
    local empty=0

    # echo -e "$query"; read
    select_query "$query"

    # Thread_list
    threads=$(echo -e "$query_result" | tail +2)

    # Are there threads to display?
    if [ -n "$threads" ];then

        # Format dialog output
        while read -r line
        do
            # title has to fill 40 chars
            # author has to fill 10 chars
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
                --cancel-label "NEW THREAD"\
                --ok-label "$ok_l"\
                --extra-button\
                --extra-label "BACK"\
                --title "$title"\
                --menu "$msg" 40 120 30\
                )

    local thread_n
    local ret=0

    # Display dialog & get feedback
    "${cmd[@]}" "${options[@]}" 2>/tmp/$usr_id || ret=1
    thread_n="$(cat /tmp/$usr_id)";thread_n="$(echo $thread_n)"
    # echo "t_id:$thread_n ret:$ret empty:$empty";read

    # Where should I go?
    if [ $ret -eq 0 -a $empty -eq 0 ]; then
        # echo "SELECT";read
        thread_id=$thread_n
        level=$(($level+1))
    elif [ -z "$thread_n" ]; then
        # echo "NEW THREAD";read
        new_thread
    elif [[ ${#thread_n} -lt 7 ]]; then
        thread_id=-1
        level=$(($level-1))
        # echo "BACK";read
    fi

}


function watch_thread()
{
    if [ $thread_id -eq -1 ];then return;fi     # Need it for repleis
    if [ $level -ne 2 ]; then return; fi        # This is level 2

    # Dialog Parameters
    local title=""              # Thread title
    local options=()
    local backtitle=$banner
    local ok_l="BACK"
    local cancel_l="REPLY"
    local extra_l="REFRESH"

    local body=""
    local posts=""
    local op=""
    local query=$(printf "$thread_op_query" "$thread_id")
    # echo "$query";read


    ## Get OP
    # Look it up in the database
    select_query "$query"

    op=$(echo -e "$query_result" | tail +2)
    reset_db
    # echo -e "$op"; read

    ## OP formatting
    local op_id="$thread_id"
    local op_title=$(echo -e "$op" | cut -d$'\t' -f2)
    local op_author=$(echo -e "$op" | cut -d$'\t' -f3)
    local op_msg=$(echo -e "$op" | cut -d$'\t' -f4 | sed -e "s/<br>/\\\\n/g")
    local op_creation=$(echo -e "$op" | cut -d$'\t' -f5)
    # echo -e "$op_id -- $op_title -- $op_author -- $op_creation\n$op_msg"; read

    title="\Zr\Zb[${op_title^^}] :: [$op_author] :: [$op_creation] :: [ID:$op_id] (Scroll: j-k)\Zn"
    body="\n$op_msg\n\n"


    ## Get posts
    query=$(printf "$thread_query" "$thread_id")

    # Look it up in the database
    select_query "$query"

    posts=$(echo -e "$query_result" | tail +2)
    reset_db
    # echo -e "posts:\n$posts"; read

    # Format posts & append to body
    while read -r line
    do
        local id=$(echo -e "$line" | cut -d$'\t' -f1)$(printf ' %.0s' {0..5});id=${id:0:5}
        local p_author=$(echo -e "$line" | cut -d$'\t' -f2)$(printf ' %.0s' {0..10});p_author=${p_author:0:10}
        local p_msg=$(echo -e "$line" | cut -d$'\t' -f3 | sed -e "s/<br>/\\\\n/g");
        local p_creation=$(echo -e "$line" | cut -d$'\t' -f4)
        local post_header=""

        # echo -e "[EXITING DB]:\n$id $p_creation $p_author\n$p_msg";sleep 0.2
        
        post_header=" \n     \Z4\Zr\Zb[ID]:$id[AUTHOR]:$p_author[CREATION]:$p_creation\Zn\n"

        body="$body$post_header\n$p_msg\n\n"

    done <<< "$(echo -e "$posts")"

    # read

    ## Display dialog
    dialog\
        --extra-label "$extra_l" --extra-button\
        --ok-label "$ok_l"\
        --cancel-label "$cancel_l"\
        --colors\
        --backtitle "$backtitle"\
        --title "$title"\
        --yesno "$body" 40 120

    local ret=$?
    # echo $ret; read

    case $ret in
        0)
            # BACK
            # echo 'BACK';read
            level=$(($level-1))
            thread_id=-1
            ;;
        3)
            # REFRESH
            # echo 'REFRESH';read
            # Do nothing, will reload this function
            ;;
        *)
            # REPLY
            # echo 'REPLY'; read
            new_reply
        ;;
    esac

}
