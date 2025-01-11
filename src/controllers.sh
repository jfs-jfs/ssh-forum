#!/bin/bash

source ./src/visuals.sh
source ./src/logger.sh
source ./src/models.sh

# The default controller used on user connection. Serves as a starting point to access to the other parts of the system.
main_controller() {
  local is_running=true

  welcome_banner
  while $is_running; do
    case $(main_menu) in
      "<Forums>")
        debug "forums selected"
        boards_controller
        ;;
      "<Chat>")
        debug "chat selected"
        chat_controller
        ;;
      "<Change name>")
        debug "config selected"
        user_name_controller
        ;;
      *)
        debug "main menu exit"
        is_running=false
    esac
  done
}

# User name controller
# Controls how to change the username
user_name_controller() {

  local ok_username=false
  local error=""
  local new_username=""

  while ! $ok_username; do
    new_username="$(user_name_form "$error" | xargs)"

    if [ -z "$new_username" ];then
      error "empty username not allowed!"
      error="Empty username"
      continue
    fi

    # Parse input
    new_username="$(echo -e "$new_username" | tr -d '\t')"
    new_username="$(echo -e "$new_username" | tr -d '\a')"
    new_username="$(echo -e "$new_username" | tr -d '\b')"
    new_username="$(echo -e "$new_username" | tr -d '\f')"
    new_username="$(echo -e "$new_username" | tr -d '\n')"
    new_username="$(echo -e "$new_username" | tr -d '\r')"
    new_username="$(echo -e "$new_username" | tr -d '\t')"
    new_username="$(echo -e "$new_username" | tr -d '\v')"

    if [ ${#new_username} -lt "$USER_NAME_MIN_LENGTH" ]; then
      error="At least $USER_NAME_MIN_LENGTH characters"
      continue
    fi

    if [ ${#new_username} -gt "$USER_NAME_MAX_LENGTH" ]; then
      error="No more than $USER_NAME_MAX_LENGTH characters"
      continue
    fi

    ok_username=true
  done

  export AUTHOR="$new_username"
}

# Chat controller
# Controller used to control the flow of execution of the chat view.
# Responsible for displaying the chat feed and processing any new message.
chat_controller() {
  touch "$CHAT_FILE"

  local exit_chat=false
  while ! $exit_chat; do
    local new_message
    new_message="$(chat_interface)"

    # Exit on empty message
    if [ -z "$new_message" ];then
      exit_chat=true
      continue
    fi

    # Parse input
    new_message="$(echo -e "$new_message" | tr -d '\t')"
    new_message="$(echo -e "$new_message" | tr -d '\a')"
    new_message="$(echo -e "$new_message" | tr -d '\b')"
    new_message="$(echo -e "$new_message" | tr -d '\f')"
    new_message="$(echo -e "$new_message" | tr -d '\n')"
    new_message="$(echo -e "$new_message" | tr -d '\r')"
    new_message="$(echo -e "$new_message" | tr -d '\t')"
    new_message="$(echo -e "$new_message" | tr -d '\v')"

    # Format input
    new_message="[$AUTHOR] @ $(date +%x--%X): $new_message"
    new_message=$(echo "$new_message" | fold -w $((CHAT_FEED_WIDTH - 2)))

    # Append to chat feed
    echo -e "$new_message\n" >> "$CHAT_FILE"
  done
}

# Boards Controller
# Controller to display list of boards and select one of them for displaying threads
boards_controller() {

  local go_back=false
  while ! $go_back;do
    local selected_board

    local boards=("<*>" "The most recently bumped threads" "${BOARDS[@]}")

    selected_board=$(board_selector_menu "${boards[@]}")

    if [ -z "$selected_board" ]; then
      go_back=true
      continue
    fi

    debug "$selected_board"
    board_controller "$selected_board"
  done
}

# Meta Board Controller
# Controller for the special board <*> which is the most recent threads inside the
# whole of the system
meta_board_controller() {
  local go_back=false
  while ! $go_back;do
    shopt -s nullglob
    local thread_files=("./boards/"*"/"*)
    shopt -u nullglob

    if [ -n "${thread_files[*]}" ];then
      # Sort them by modification date
      debug "pre sorted thread files -> ${thread_files[*]}"
      IFS=$'\n' thread_files=($(ls -t "${thread_files[@]}"))
      debug "sorted thread files -> ${thread_files[*]}"

      thread_files=("${thread_files[@]:0:$MAX_ACTIVE_THREADS_PER_BOARD}")
    fi

    # Generate titles out of them
    mapfile -t thread_titles <<< "$(paths_to_thread_board_titles "${thread_files[@]}")"

    # Display them and wait for user input
    local selected_thread
    selected_thread="$(thread_selector_meta_menu "${thread_titles[@]}")"

    # Process input
    debug "Thread selection -> $selected_thread"
    case "$selected_thread" in
      "BACK") go_back=true ;;
      "NEW THREAD") thread_creation_controller "$board_dir" ;;
      *)
        local clean_thread_file="$(xargs <<< "$selected_thread")"
        thread_controller "$(dirname "$clean_thread_file")" "$(basename "$clean_thread_file")"
      ;;
    esac

  done
}

# Board Controller
# Controls how the threads in a board should be displayed given a board name
board_controller() {
  if [ $# != 1 ]; then
    error "Called board controller without board argument!!"
    return
  fi


  local board="$1"
  if [ "$board" = "<*>" ]; then
    meta_board_controller
    return
  fi

  local board_dir="./boards/$board"
  debug "Board controller for -> $board"

  if [ ! -d "$board_dir" ];then
    debug "Board directory doesnt exist. Creating it! [$board]"
    mkdir "$board_dir" 
  fi

  local go_back=false
  while ! $go_back; do

    # Get thread files on board
    local thread_files
    shopt -s nullglob
    thread_files=("$board_dir/"*)
    shopt -u nullglob

    if [ -n "${thread_files[*]}" ];then
      # Sort them by modification date
      debug "pre sorted thread files -> ${thread_files[*]}"
      IFS=$'\n' thread_files=($(ls -t "${thread_files[@]}"))
      debug "sorted thread files -> ${thread_files[*]}"

      thread_files=("${thread_files[@]:0:$MAX_ACTIVE_THREADS_PER_BOARD}")
    fi

    # Generate titles out of them
    mapfile -t thread_titles <<< "$(paths_to_thread_titles "${thread_files[@]}")"

    # Display them and wait for user input
    local selected_thread
    selected_thread="$(thread_selector_menu "${thread_titles[@]}")"

    # Process input
    debug "Thread selection -> $selected_thread"
    case "$selected_thread" in
      "BACK") go_back=true ;;
      "NEW THREAD") thread_creation_controller "$board_dir" ;;
      *) thread_controller "$board_dir" "$(xargs <<< "$selected_thread")" ;;
    esac
  done
}

# Thread creation controller
# Guides and handles the process of thread creation
# Arguments:
#   - board directory
thread_creation_controller() {
  info "thread_creation_controller"
  if [ $# -ne 1 ]; then
    error "Called thread creation controller without necessary arguments!!"
    error "-- Board dir is missing"
    return
  fi

  local board_dir="$1"
  if [ ! -d "$board_dir" ]; then
    error "Board at $board_dir does not exist"
    return
  fi

  local valid_title=false
  local thread_title=""
  local new_thread_file=""
  local error=""

  while ! $valid_title; do
    thread_title="$(thread_title_form "$error" | xargs)"

    if [ -z "$thread_title" ]; then
      info "Empty thread title -> going back!"
      return
    fi

    # Parse input
    thread_title="$(echo -e "$thread_title" | tr -d '\t')"
    thread_title="$(echo -e "$thread_title" | tr -d '\a')"
    thread_title="$(echo -e "$thread_title" | tr -d '\b')"
    thread_title="$(echo -e "$thread_title" | tr -d '\f')"
    thread_title="$(echo -e "$thread_title" | tr -d '\n')"
    thread_title="$(echo -e "$thread_title" | tr -d '\r')"
    thread_title="$(echo -e "$thread_title" | tr -d '\t')"
    thread_title="$(echo -e "$thread_title" | tr -d '\v')"
    thread_title="$(echo -e "$thread_title" | tr -d '*')"
    thread_title="$(echo -e "$thread_title" | tr -d '/')"
    debug "-> New thread title -> $thread_title"

    if [ ${#thread_title} -gt "$THREAD_TITLE_MAX_LENGTH" ]; then 
      error "thread title too long!"
      error="The title is longer than $THREAD_TITLE_MAX_LENGTH chars"
      continue
    fi

    if [ ${#thread_title} -lt "$THREAD_TITLE_MIN_LENGTH" ]; then 
      error "thread title too short"
      error="The title is shorter than $THREAD_TITLE_MIN_LENGTH chars"
      continue
    fi

    new_thread_file="$board_dir/$thread_title"
    if [ -f "$new_thread_file" ]; then
      error "thread with same name already exists in this board"
      error="The thread name is already taken"
      continue
    fi

    valid_title=true
  done

  error=""
  local thread_body=""
  local valid_body=false
  while ! $valid_body; do
    thread_body="$(thread_body_form "$thread_title" "$error" "$thread_body")"
    if [ -z "$thread_body" ]; then
      info "Empty thread body -> going back!"
      return
    fi

    if [ ${#thread_body} -lt "$THREAD_BODY_MIN_LENGTH" ]; then
      error "thread body too short!"
      error="Body is too short"
      continue
    fi

    if [ ${#thread_body} -gt "$THREAD_BODY_MAX_LENGTH" ]; then
      error "thread body too long!"
      error="Exceeds $THREAD_BODY_MAX_LENGTH characters (by $((${#thread_body} - THREAD_BODY_MAX_LENGTH))"
      continue
    fi

    thread_body="$(highlight_urls_in_thread_body "$thread_body")"
    thread_body="$(highlight_green_text "$thread_body")"

    valid_body=true
  done

  touch "$new_thread_file"
  echo -e "0\n$AUTHOR\n$(date '+%x %X')\n\n$thread_body\n" >> "$new_thread_file"

  if [ "$(ls | wc -l)" -gt "$MAX_ACTIVE_THREADS_PER_BOARD" ]; then
    local oldest_file
    oldest_file="$(find "$board_dir" -type f -printf '%T+%p\n' | sort | head -n1)"
    oldest_file="${oldest_file:31}"
    debug "oldest file -> $oldest_file"

    mkdir -p "$ARCHIVE/$board_dir"
    mv "$oldest_file" "$ARCHIVE/$board_dir/$oldest_file"
  fi
}

# Thread controller
# Controlls the display of the thread as well as what to do with user action at this stage
# Arguments:
#   - board directory
#   - thread filename
thread_controller() {

  if [ $# -ne 2 ]; then
    error "Called thread controller without necessary arguments!!"
    error "-- Either board dir is missing or thread file is missing or both"
    return
  fi

  local thread_file="$1/$2"
  if [ ! -f "$thread_file" ]; then
    error "The thread file '$thread_file' does not exist!"
    return
  fi

  local go_back=false
  while ! $go_back; do

    local title
    local thread_body
    local replies

    title="[ $(thread_file_to_thread_title "$thread_file") ] :: [ $(thread_file_to_thread_author "$thread_file") ] :: [ $(thread_file_to_thread_creation_date "$thread_file") ] (j-k to scroll)"
    thread_body="$(thread_file_to_thread_body "$thread_file")"
    replies="$(thread_file_to_thread_replies "$thread_file")"

    local locked_thread=false
    if [ "$replies" -gt "$MAX_REPLIES_PER_THREAD" ];then locked_thread=true; fi

    local action
    action="$(display_thread "$title" "$thread_body" "$locked_thread")"

    debug "$action"
    case "$action" in
      "BACK") go_back=true ;;
      "NEW REPLY") new_reply_controller "$thread_file";;
      *) error "How the fuck did I even end here?!!" ;;
    esac

  done
}

# New Reply controller
# Controls the display of forms to create a new reply and also processes the new reply
# Arguments:
#   - The filepath to the thread file
new_reply_controller() {
  if [ $# -ne 1 ]; then
    error "Called new reply controller with missing argument 'filepath'"
    return
  fi

  local filepath="$1"
  if [ ! -f "$filepath" ]; then
    error "Thread file: $filepath does not exist on the system! Unable to add reply to it!"
    return
  fi

  local thread_title
  local thread_replies
  thread_title="$(thread_file_to_thread_title "$filepath")"
  thread_replies="$(thread_file_to_thread_replies "$filepath")"

  local error=""
  local reply_body=""
  local valid_reply=false
  while ! "$valid_reply"; do
    reply_body="$(new_reply_form "$thread_title" "$error" "$reply_body" | cat -s)"
    if [ -z "$reply_body" ]; then
      info "Empty reply body -> going back!"
      return
    fi

    if [ ${#reply_body} -lt "$REPLY_MIN_LENGTH" ]; then
      error "reply body too short!"
      error="Reply is too short"
      continue
    fi

    if [ ${#reply_body} -gt "$REPLY_MAX_LENGTH" ]; then
      error "reply body too long!"
      error="Exceeds $REPLY_MAX_LENGTH charactes (by $((${#reply_body} - REPLY_MAX_LENGTH)))"
      continue
    fi

    reply_body="$(highlight_urls_in_thread_body "$reply_body")"
    reply_body="$(highlight_green_text "$reply_body")"
    reply_body="$(highlight_references_in_thread_boady "$reply_body")"

    valid_reply=true
  done

  # Worth to queue writings to file for race conditions? Meeh
  # Update replies
  local next_reply_number=$((thread_replies+1))
  sed -i "1s/.*/$next_reply_number/" "$filepath"

  # Add reply
  reply_body="$(fold -w $((THREAD_FEED_WIDTH - 6)) <<< "$reply_body" | sed -e 's/^/ /')"
  echo -e "\Z5[[$AUTHOR :: $(date '+%x %X') :: #$next_reply_number]]\Zn\n$reply_body\Zn\n" >> "$filepath"
}
