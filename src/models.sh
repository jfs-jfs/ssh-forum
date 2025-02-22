#!/bin/bash

source ./src/logger.sh

# Transform the path to files containing the threads to the representation needed to display them on screen.
paths_to_thread_titles() {
  local paths=("$@")

  for file in "${paths[@]}"; do
    if [ ! -f "$file" ]; then
      error "Unable to find file -> $file"
      continue
    fi

    local t_title="$(basename "$file")$(printf ' %.0s' {0..40})"
    local t_last_reply="$(date -r "$file" '+%x %X')"
    local t_replies="$(head -n1 "$file")"
    local t_author="$(head -n2 "$file" | tail -n1)          "

    t_title=${t_title:0:40}
    t_author=${t_author:0:10}

    echo "$t_title"
    echo "$t_author :: $t_replies :: $t_last_reply"
  done
}

paths_to_thread_board_titles() {
  local paths=("$@")

  for file in "${paths[@]}"; do
    if [ ! -f "$file" ]; then
      error "Unable to find file -> $file"
      continue
    fi

    local t_title="$file$(printf ' %.0s' {0..60})"
    local t_last_reply="$(date -r "$file" '+%x %X')"
    local t_replies="$(printf "%0.3d" "$(thread_file_to_thread_replies "$file")")"
    local t_author="$(thread_file_to_thread_author "$file")          "

    t_title=${t_title:0:60}
    t_author=${t_author:0:10}

    echo "$t_title"
    echo "$t_author :: $t_replies :: $t_last_reply"
  done
}

# Extracts the author name of a given thread file
# Arguments:
#   - thread file path
thread_file_to_thread_author() {
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    error "File does not exist! -> $1"
    return
  fi
  head -n2 "$1" | tail -n1
}

# Extracts the number of replies given a path to a thread file
# Arguments:
#   - Thread File Path
thread_file_to_thread_replies() {
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    error "File does not exist! -> $1"
    return
  fi
  head -n1 "$1"
}

# Extracts the thread title given a path to a thread file
# Arguments:
#   - thread file path
thread_file_to_thread_title() {
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    error "File does not exist! -> $1"
    return
  fi

  basename "$1"
}

# Extracts the thread contents given a path to the thread file
# Arguments:
#   - Thread file path
thread_file_to_thread_body() {
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    error "File does not exist! -> $1"
    return
  fi

  tail -n+4 "$1"
}

# Extracts the thread creation date given a path to a thread file
# Arguments:
#   - thread file path
thread_file_to_thread_creation_date() {
  if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    error "File does not exist! -> $1"
    return
  fi

  head -n3 "$1" | tail -n1
}

# Highlight URLs given a text
# Arguments:
#   - text to highlight
highlight_urls_in_thread_body() {
  if [ $# -ne 1 ]; then
    error "Missing body to work with"
    return
  fi

  local url_regex="https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,4}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
  local higlight_pattern="\\\\Zb\\\\Zu\\0\\\\Zn"

  echo -E "$1" | sed -E "s/$url_regex/$higlight_pattern/g" 
}

# Highlight references given a text
# Arguments:
#   - text to highlight
highlight_references_in_thread_boady() {
  if [ $# -ne 1 ]; then
    error "Missing body to work with"
    return
  fi

  local ref_regex="#[0-9]+"
  local higlight_pattern="\\\\Zb\\\\Z5\\0\\\\Zn"

  echo -E "$1" | sed -E "s/$ref_regex/$higlight_pattern/g" 
}

# Highlight green text given a text
# Arguments:
#   - text to highlight
highlight_green_text() {
  if [ $# -ne 1 ]; then
    error "Missing body to work with"
    return
  fi

  local green_text_regex=">.+"
  local higlight_pattern="\\\\Zb\\\\Z2\\0\\\\Zn"

  echo -E "$1" | sed -E "s/$green_text_regex/$higlight_pattern/g" 
}
