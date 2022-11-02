#!/bin/bash

### Chat related
CHAT_FILE="/tmp/chat"
MAX_CHAT_MSG_LEN=244

## Ensure the chat server file exists
if [ ! -f "$CHAT_FILE" ];then touch "$CHAT_FILE"; fi

### Functions
function start_chat()
{
    local title="...Chat..."
    local backtitle=$banner

    #echo "enters"; read

    while true;
    do
        dialog --backtitle "$backtitle"\
            --title "$title" --keep-window\
            --begin 2 2 --colors\
            --tailboxbg "$CHAT_FILE" 30 110\
            --and-widget\
            --begin 34 2\
            --ok-label "SEND" --cancel-label "BACK"\
            --max-input $MAX_CHAT_MSG_LEN\
            --inputbox "*Use up arrow to change focus\n*Empty box is treated as BACK" 8 110\
             2>/tmp/$usr_id || break

        ## Process input
        local msg="$(cat /tmp/$usr_id)"
        if [ -z "$msg" ];then break; fi         # Break if box is empty

        #CLEAN INPUT
        msg=${msg:0:$MAX_CHAT_MSG_LEN}
        msg=$(echo "$msg" | sed -e 's/\\//g')

        #ADD AUTHOR AND TIMESTAMP
        msg="[$new_author]$(date +%x--%X)\n -> $msg"
        msg=$(echo "$msg" | fold -w 110)
        msg="$msg\n-------------------------------------------------------"

        ## Append it to CHAT_FILE and resize to max size
        echo -e "$msg" >> "$CHAT_FILE"
    done
}
