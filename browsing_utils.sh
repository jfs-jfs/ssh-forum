#!/bin/bash

### Globals
level=0             # Control where is the user
board_id=-1         # Board to display
thread_id=-1        # Thread to display
queried_boards=1    # Do not oversaturate the database
boards=()           # Boards to pick from
max_iterations=500  # Break if something goes wrong


# If query fails
readonly error_msg="Something went wrong. If persists report it to github.com/analogcity\nPres enter to continue...";

### Queries

# Board related
readonly board_query="SELECT id, name, description FROM board"
readonly thread_list_query="SELECT id, title, creation, author, num_replies, is_pinned FROM thread WHERE board_id=%d ORDER BY is_pinned DESC, last_reply DESC LIMIT 25"
readonly all_thread_list_query="SELECT id, title, creation, author, num_replies, is_pinned FROM thread ORDER BY is_pinned DESC, last_reply DESC LIMIT 25"

# Thread related
readonly thread_query="SELECT processed_text FROM post WHERE thread_id=%d ORDER BY creation"
readonly thread_op_query="SELECT num_replies, processed_op, body FROM thread WHERE id=%d"

### Functions

function look_around()
{

    # echo "$level";read

    while [ $level -ge 0 ] && [ $max_iterations -ge 0 ];
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
        max_iterations=$((max_iterations-1))
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
        local res="$query_result"
        reset_db

        ## Add a board for all
        options+=("*" "<All>         :: The most recently bumped threads")
        # Prase database output
        while read -r line
        do
            local id=$(echo -e "$line" | cut -d'|' -f1)
            local name="<$(echo -e "$line" | cut -d'|' -f2)>$(printf " %.0s" {0..14})";name=${name:0:14}
            local desc=$(echo -e "$line" | cut -d'|' -f3)

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
        level=$((level-1))
    else
        level=$((level+1))
    fi

}

function select_thread()
{
    if [ $board_id -eq -1 ];then return;fi  # Return to pick board
    if [ $level -ne 1 ]; then return; fi    # This is level 1

    # Dialog parameters
    local backtitle=$banner
    local title="...Pick a thread..."
    local msg="Pick the thread you would like to explore:"
    local ok_l="SELECT";
    local options=()
    local query=""
    local empty=0

    if [ "$board_id" = "*" ];then
        query="$all_thread_list_query"
    else
        query=$(printf "$thread_list_query" "$board_id")
    fi

    # echo -e "$query"; read
    select_query "$query"

    # Thread_list
    threads="$query_result"
    # echo "$threads"; read

    # Are there threads to display?
    if [ -n "$threads" ];then

        # Format dialog output
        while read -r line
        do
            # title has to fill 40 chars
            # author has to fill 10 chars
            local id=$(echo -e "$line" | cut -d'|' -f1)
            local t_title="$(echo -e "$line" | cut -d'|' -f2 )$(printf ' %.0s' {0..40})";t_title=${t_title:0:40}
            local t_creation=$(echo -e "$line" | cut -d'|' -f3)
            local t_author="$(echo -e "$line" | cut -d'|' -f4)$(printf ' %.0s' {0..10})";t_author=${t_author:0:10}
            local t_replies=$(echo -e "$line" | cut -d'|' -f5)
            local t_pinned=$(echo -e "$line" | cut -d'|' -f6)


            # echo -e "$line";read;
            # echo -e "id:$id title:$t_title creation:$t_creation author:$t_author replys:$t_replies p:$t_pinned";sleep 0.2
            if [ $t_pinned -eq 1 ]; then
                options+=("$id" "$t_author:: \Z4${t_title^^}\Zn$t_creation -- $t_replies")
            else
                options+=("$id" "$t_author:: \Z5${t_title^^}\Zn$t_creation -- $t_replies")
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
    thread_n="$(cat /tmp/$usr_id)";
    # echo "t_id:$thread_n ret:$ret empty:$empty";read

    # Where should I go?
    if [ $ret -eq 0 ] && [ $empty -eq 0 ]; then
        # echo "SELECT";read
        thread_id=$thread_n
        level=$((level+1))
    elif [ -z "$thread_n" ]; then
        # echo "NEW THREAD";read
        new_thread
    elif [[ ${#thread_n} -lt 7 ]]; then
        thread_id=-1
        level=$((level-1))
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

    local locked_thread=0
    local body=""
    local op=""
    local query=$(printf "$thread_op_query" "$thread_id")
    # echo "$query";read

    ## Get OP
    # Look it up in the database
    select_query "$query"

    op="$query_result"
    reset_db
    # echo -e "$op"; read

    ## Thread metainfo
    local t_replies=$(echo -e "$op" | cut -d'|' -f1)

    # Should the thread be locked to replys?
    if [ $t_replies -ge $bump_limit ] && [ $t_pinned -ne 1 ]; then
        locked_thread=1
        extra_l="BACK"
        cancel_l="MAXED REPLIES"
    fi
    
    title=$(echo -e "$op" | cut -d'|' -f2)
    body="\n$(echo -e "$op" | cut -d'|' -f3)\n\n"


    ## Get posts
    query=$(printf "$thread_query" "$thread_id")

    # Look it up in the database
    select_query "$query"
    body="$body$(echo -e "$query_result")"
    reset_db

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

    if [ $locked_thread -eq 1 ]; then ret=0; fi

    case $ret in
        0)
            # BACK
            # echo 'BACK';read
            level=$((level-1))
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
