function welcome()
{
    dialog --backtitle "$banner" \
        --title "...Welcome..."\
        --msgbox "
Whoever you are, whom the chances of the Internet have led here, welcome. Here you will find nothing or little of what the world today appreciates. Neither the concern of being different.

"\
        10 60
}

function create_post_body()
{
    local zero=0
    local free=0
    while [ $free -eq $zero ];
    do
        free=1
        dialog  --backtitle "$banner" \
            --title "...What do you have to say? (1k max.)..."\
            --no-cancel\
            --max-input 1024\
            --editbox /tmp/$id \
            20 120 2>/tmp/$id
        
        content=$(cat /tmp/$id)
        content=${content:0:1024}

        ## Clean input and set break lines
        content=$(printf "$content" | sed -e 's/[\"\\\;\<]/ /g' -e 's/'"'"'/'"\\'"'/g' -e '/^$/d')

        if [ ${#content} -eq 0 ];
        then
            dialog --backtitle "$banner"\
                --title "...Error..."\
                --no-cancel\
                --msgbox "You can not submit an empty body"\
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

    content=$(\
                printf "$content" |\
                tr '\n' ';' |\
                sed -e 's/\;/<br>/g'\
            )

    # Prase the references
    if [ $debug -e 0 ];
    then
        content=$(../bin/./postref "$content")
        content=$(../bin/./greentext "$content")
    else
        content=$(/home/lowlife/bin/./postref "$content")
        content=$(/home/lowlife/bin/./greentext "$content")
    fi

}

function add_thread()
{
    local query="INSERT INTO thread (author,table_id,comment,image_link,title, poster_ip)\
    VALUES ('$author', (SELECT id FROM board WHERE link = '$link'), '$content', 'img', '$title', '$ip')"
    
    mysql -u$USER -p$PASS $BDNAME -e "$query" &>/dev/null
    content=""
}

function add_reply()
{
    local query="INSERT INTO post (author,thread_id,comment,image_link, poster_ip)\
                VALUES ( '$author', $thread_n, '$content', 'img', '$ip')"
    mysql -u$USER -p$PASS $BDNAME -e "$query" &>/dev/null
    content=""
    mysql -u$USER -p$PASS $BDNAME -e "UPDATE thread set replays = replays + 1 where id = $thread_n" &>/dev/null
    
}

function get_option()
{
    option=$(\
    dialog --backtitle "$banner" \
        --title "...Decisions..."\
        --no-cancel\
        --menu "Please choose one option:"\
        12 80 4\
        "<Start a thread>"  "Create a new thread in one of the system boards."\
        "<Reply a thread>"  "Make an insightfull comment or a shitpost."\
        "<Admin Tools>"     ""\
        "<Exit>"            "Exit the system."\
        3>&1 1>&2 2>&3 3>&-\
    )
}

function new_reply()
{
    local free=0
    local zero=0
    while [ $free -eq $zero ];
    do
        free=1
        ### Ask for thread number and other stuf
        dialog --backtitle "$banner"\
                --title "...New Reply Form..."\
                --form "Please fill all the fields in the form. Switch between fields with the Arrow keys. To jump to the <OK> use the <Tab> key, also pressing <Enter> confirms the form."\
                20 60 7\
                "[Thread id]:"  1 13 ""          1 27 3 2\
                "[Author]:"     3 13 "$author"     3 27 20 20\
                "[IP]:"         5 13 "$ip"       5 27 -20 0\
                2>/tmp/$id || return

        thread_n=$(head -n1 /tmp/$id | tr -cd "[0-9]")
        author=$(tail -n1 /tmp/$id | sed -e 's/[\"\\\;\<\>'"'"']/ /g')
        rm /tmp/$id

        if [ -z $author ];
            then
                dialog --backtitle "$banner" \
                    --title "...Error..."\
                    --msgbox "Please fill the author field next time."\
                    10 60
                free=0
                continue
        fi
    
        ## Ask if it looks okay or not
        dialog --backtitle "$banner" \
            --title "...OK?..."\
            --yesno "Does the following look good to you?

            Thread id: $thread_n
            Author: $author"\
            8 50 \
            || free=0
    done

    ### Create the body of the post
    touch /tmp/$id
    create_post_body
    rm /tmp/$id
    add_reply

    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "Your Post has been published successfully."\
        8 60
}

function get_board_link()
{
    case $board in
    "<The highway>")
    link='i'
    ;;
    "<Meatspace>")
    link='h'
    ;;
    "<Meta>")
    link='m'
    ;;
    "<Programming>")
    link='c'
    ;;
    "<Random>")
    link='b'
    ;;
    *)
    exit
    ;;
    esac

}

function new_thread()
{
    ## Pick board       --- TODO :: make it dynamic
    board=$(\
        dialog --backtitle "$banner" \
            --title "...Decisions..."\
            --menu "Please choose a board to create a thread on:"\
            13 80 5\
            "<The highway>" "Share info, doesn't matter the subject."\
            "<Meatspace>" "Humanities, rants, experiences. Here is the place."\
            "<Programming>" "Share projects, tips, resources or ask questions."\
            "<Meta>" "For dicussion about the site and updates."\
            "<Random>" "Everything else."\
            3>&1 1>&2 2>&3 3>&-\
    )

    if [ -z "$board" ];
    then
        return
    fi

    get_board_link

    local free=0
    local zero=0
    while [ $free -eq $zero ];
    do
        free=1
        ## Fill up the form
        dialog --backtitle "$banner"\
            --title "...New Thread Form..."\
            --form "Please fill all the fields in the form. Switch between fields with the Arrow keys. To jump to the <OK> use the <Tab> key, also pressing <Enter> confirms the form."\
            20 60 9\
            "[Title]:"  1 15 ""          1 27 20 100\
            "[Board]:"  3 15 "$board"    3 27 -20 0\
            "[Author]:" 5 15 "$author"     5 27 20 20\
            "[IP]:"     7 15 "$ip"       7 27 -20 0\
            2>/tmp/$id || return

        title=$(head -n1 /tmp/$id | sed -e 's/[\"\\\;\<\>]/ /g' -e 's/'"'"'/'"\\'"'/g')
        author=$(tail -n1 /tmp/$id | sed -e 's/[\"\\\;\<\>'"'"']/ /g')
        rm /tmp/$id

        ## Check for empty field
        if [ -z $title ];
        then
            dialog --backtitle "$banner" \
                --title "...Error..."\
                --msgbox "Please fill the title field next time."\
                10 60
            free=0
            continue
        fi

        if [ -z $author ];
        then
            dialog --backtitle "$banner" \
                --title "...Error..."\
                --msgbox "Please fill the author field next time."\
                10 60
            free=0
            continue
        fi

        ## Ask if it looks okay or not
        dialog --backtitle "$banner" \
            --title "...OK?..."\
            --yesno "Does the following look good to you?

            Title: $title
            Author: $author"\
            8 50 \
            || free=0
    done

    ### Create the body of the post
    touch /tmp/$id
    create_post_body
    rm /tmp/$id
    add_thread

    dialog --backtitle "$banner" \
        --title "...Commited Changes..."\
        --sleep 2\
        --infobox "Your Thread has been published successfully."\
        8 60
}
