#!/bin/bash

# Displays the welcome banner. The contents of it are declared inside the file ´assets/welcome_banner´ 
welcome_banner() {
  local title='[[Welcome]]'
  dialog --backtitle "$BANNER"\
    --title "$title"\
    --msgbox "\n$(cat ./assets/welcome_banner)\n"\
    "$WELCOME_HEIGHT" "$WELCOME_WIDTH"
}

# Displays the main menu and returns the option picked by the user.
# The return values can be: "<Forums>", "<Chat>", "<Change name>" and "".
# The empty string means no option was picked
main_menu() {
  local title="[[Where shall we go?]]"
  dialog --backtitle "$BANNER"\
    --title "$title"\
    --cancel-label "EXIT"\
    --stdout\
    --menu "UP & DOWN to move selection, TAB to select action"\
    "$MAIN_MENU_HEIGHT"\
    "$MAIN_MENU_WIDTH"\
    "$MAIN_MENU_MENU_HEIGHT"\
    "<Forums>"    "Explore and participate in forums"\
    "<Chat>"      "Chat with other users"\
    "<Change name>"    "Change site settings"
}

# Displays the interface for the chat.
# One big bacground tail box and a small input box under it.
# Returns whatever is introduced into the input box
chat_interface() {
  local title="[[Chat Feed]]"
  dialog --backtitle "$BANNER"\
    --title "$title"\
    --begin 2 2 --colors\
    --keep-window\
    --tailboxbg "$CHAT_FILE"\
    "$CHAT_FEED_HEIGHT"\
    "$CHAT_FEED_WIDTH"\
    --and-widget\
    --stdout\
    --begin 32 2\
    --ok-label "SEND"\
    --cancel-label "BACK"\
    --max-input "$CHAT_MSG_MAX_LENGTH"\
    --inputbox "*Use up arrow to chage focus\n*Empty box is treated as BACK"\
    "$CHAT_INPUT_HEIGHT"\
    "$CHAT_INPUT_WIDTH"
}

# Displays a menu to select a board
# Arguments:
#   - The list of boards (shouldnt be empty!)
# Returns:
#   - The selected Board or empty when op cancellation
board_selector_menu() {
  local title="[[Board Selection]]"
  local boards=("$@")
  local msg="UP & DOWN to move selection, TAB to select action"

  dialog --backtitle "$BANNER"\
    --title "$title"\
    --stdout\
    --cancel-label "BACK"\
    --ok-label "SELECT"\
    --menu "$msg"\
    "$BOARD_SELECTOR_HEIGHT"\
    "$BOARD_SELECTOR_WIDTH"\
    "$BOARD_SELECTOR_MENU_HEIGHT"\
    "${boards[@]}"
}

# Displays thread selector menu for the meta board.
# Returns either the selected thread name, BACK on back selected and NEW THREAD on new thread selected.
# Arguments:
#   - threads Required
thread_selector_meta_menu() {
  local title="[[Thread Selection]]"
  local msg="UP & DOWN to move selection, TAB to select action"
  local ok_label="SELECT"
  local threads=("$@")

  if [ -z "${threads[*]}" ]; then
    threads=("EMPTY" "BOARD")
    ok_label="BACK"
  fi

  local selected_thread
  selected_thread="$(dialog --backtitle "$BANNER"\
    --colors\
    --stdout\
    --title "$title"\
    --ok-label "$ok_label"\
    --cancel-label "BACK"\
    --menu "$msg"\
    "$THREAD_SELECTOR_HEIGHT"\
    "$THREAD_SELECTOR_WIDTH"\
    "$THREAD_SELECTOR_MENU_HEIGHT"\
    "${threads[@]}")"

  ret=$?
  debug "return code -> $ret"
  case "$ret" in
    0)
      if [ "EMPTY" = "$selected_thread" ]; then
        echo "BACK"
      else
        echo "$selected_thread" 
      fi
      ;;
    *) echo "BACK" ;;
  esac
}
# Displays thread selector menu.
# Returns either the selected thread name, BACK on back selected and NEW THREAD on new thread selected.
# Arguments:
#   - threads Required
thread_selector_menu() {
  local title="[[Thread Selection]]"
  local msg="UP & DOWN to move selection, TAB to select action"
  local ok_label="SELECT"
  local threads=("$@")

  if [ -z "${threads[*]}" ]; then
    threads=("EMPTY" "BOARD")
    ok_label="BACK"
  fi

  local selected_thread
  selected_thread="$(dialog --backtitle "$BANNER"\
    --colors\
    --stdout\
    --title "$title"\
    --ok-label "$ok_label"\
    --cancel-label "BACK"\
    --extra-button --extra-label "NEW THREAD"\
    --menu "$msg"\
    "$THREAD_SELECTOR_HEIGHT"\
    "$THREAD_SELECTOR_WIDTH"\
    "$THREAD_SELECTOR_MENU_HEIGHT"\
    "${threads[@]}")"

  ret=$?
  exec 3>&-
  case "$ret" in
    0)
      if [ "EMPTY" = "$selected_thread" ]; then
        echo "BACK"
      else
        echo "$selected_thread" 
      fi
      ;;
    1) echo "BACK" ;;
    3) echo "NEW THREAD" ;;
    *) echo "BACK" ;;
  esac
}

# Display Thread
# Formats a thread into a view for the user
# Arguments:
#   - Thread title
#   - Thread body
#   - Wether it is blocked or not
# Returns:
#   - BACK
#   - NEW REPLY
display_thread() {
  if [ $# -ne 3 ]; then
    error "Missing arguments to be able to display thread!"
    return
  fi

  local title="$1"
  local body="$2"
  local is_blocked="$3"
  local new_reply_label

  if $is_blocked; then
    new_reply_label="BACK"
  else
    new_reply_label="NEW REPLY"
  fi

  local new_reply=true
  dialog --backtitle "$BANNER"\
    --title "$title"\
    --yes-label "$new_reply_label"\
    --no-label "BACK"\
    --colors\
    --stdout\
    --yesno "$body" "$THREAD_FEED_HEIGHT" "$THREAD_FEED_WIDTH" || new_reply=false

  if $new_reply;then
    echo "NEW REPLY"
  else
    echo "BACK"
  fi
}

# Thread title Form
# Prompts the user for a title for a thread
# Arguments:
#   - Error to display in case of any
# Returns:
#   - Unvalidated title string or empty string on cancelation
thread_title_form() {
  local error=""
  local title="[ New Thread ] :: [ Set title ]"

  if [ -n "$1" ]; then error="$1"; fi

  dialog --backtitle "$BANNER"\
    --title "$title"\
    --stdout\
    --colors\
    --ok-label "NEXT"\
    --max-input "$THREAD_TITLE_MAX_LENGTH"\
    --inputbox "Between $THREAD_TITLE_MIN_LENGTH and $THREAD_TITLE_MAX_LENGTH characters. Empty string is treated as CANCEL.\n\\Z1\\Zb$error\\Zn"\
    "$THREAD_TITLE_FORM_HEIGHT"\
    "$THREAD_TITLE_FORM_WIDTH"
}

# User name form
# Prompts the user for a new name to use
# Arguments:
#   - Error to display in case of any
# Returns:
#   - Unvalidated title string or empty string on cancelation
user_name_form() {
  local error=""
  local title="[[New Name]]"

  if [ -n "$1" ]; then error="$1"; fi

  dialog --backtitle "$BANNER"\
    --title "$title"\
    --stdout\
    --colors\
    --ok-label "NEXT"\
    --max-input "$USER_NAME_MAX_LENGTH"\
    --inputbox "Between $USER_NAME_MIN_LENGTH and $USER_NAME_MAX_LENGTH characters. Blank treated as Cancel.\n\\Z1\\Zb$error\\Zn"\
    "$USER_NAME_FORM_HEIGHT"\
    "$USER_NAME_FORM_WIDTH"
}

# Thread body form
# Promts the user for the body of the thread
# Arguments:
#   - thread title (Required)
#   - error in case of any
#   - default contents
# Returns:
#   - A string representing the body of the text or empty in case of cancelation
thread_body_form() {
  debug "thread_body_form"
  if [ -z "$1" ]; then
    error "Missing thread title!"
    return
  fi

  local error=""
  local contents=""
  local title="[ New Thread ] :: [ $1 ] :: [ Set Body ]"

  if [ -n "$2" ]; then error="$2"; fi
  if [ -n "$3" ]; then contents="$3"; fi

  if [ -n "$error" ]; then 
    title="!! $error !! - $title"
  fi

  local target_file="/tmp/$(date +%s%N)"
  touch "$target_file"
  echo -e "$contents" > "$target_file"

  local result
  result="$(dialog --backtitle "$BANNER"\
    --title "$title"\
    --stdout\
    --colors\
    --ok-label "CONFIRM"\
    --editbox "$target_file"\
    "$THREAD_BODY_FORM_HEIGHT" "$THREAD_BODY_FORM_WIDTH")"

  rm "$target_file"
  echo -e "$result"
}

# Displays a text form and the thread.
# Arguments:
#   - thread_title (required)
#   - error (optional)
#   - contents (optional)
# Returns:
#   - the inputed contents (Empty is considered operation cancellation)
new_reply_form() {

  debug "new_reply_form"
  if [ -z "$1" ]; then
    error "Missing thread title!"
    return
  fi

  local error=""
  local contents=""
  local title="[ Modify Thread ] :: [ $1 ] :: [ Add Reply ]"

  if [ -n "$2" ]; then error="$2"; fi
  if [ -n "$3" ]; then contents="$3"; fi

  if [ -n "$error" ]; then 
    title="!! $error !! - $title"
  fi

  local target_file="/tmp/$(date +%s%N)"
  touch "$target_file"
  echo -e "$contents" > "$target_file"

  local result
  result="$(dialog --backtitle "$BANNER"\
    --title "$title"\
    --stdout\
    --colors\
    --ok-label "CONFIRM"\
    --editbox "$target_file"\
    "$REPLY_FORM_HEIGHT" "$REPLY_FORM_WIDTH")"

  rm "$target_file"
  echo -e "$result"
}

