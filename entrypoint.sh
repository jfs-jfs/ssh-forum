#!/bin/bash
## Set locale for special chars
export LC_ALL=en_US.UTF-8

# Imports
source ./src/logger.sh
source ./src/controllers.sh

# Config vars #
# Logs
export LOG_LEVEL=$LOG_DEBUG
export LOG_FILE="analog.logs"

# Archived threads location
export ARCHIVE="archive"

# Chat
export CHAT_FILE="chat.feed"
export CHAT_MSG_MAX_LENGTH=200

# Forum
export THREAD_TITLE_MAX_LENGTH=40
export THREAD_TITLE_MIN_LENGTH=5

export THREAD_BODY_MAX_LENGTH=1024
export THREAD_BODY_MIN_LENGTH=20

export REPLY_MAX_LENGTH=1024
export REPLY_MIN_LENGTH=2

export MAX_ACTIVE_THREADS_PER_BOARD=28
export MAX_REPLIES_PER_THREAD=120

export BANNER="[!]AnalogCity :: Interface v3.0[!]"
export BOARDS=(\
  "Board Name" "Description"\
)

# User defualts
export USER_NAME_MAX_LENGTH=12
export USER_NAME_MIN_LENGTH=3
export AUTHOR="pagan"
export DIALOGRC="./assets/themes/analog.dialogrc"

# User interface
export WELCOME_WIDTH=60
export WELCOME_HEIGHT=10

export MAIN_MENU_WIDTH=80
export MAIN_MENU_HEIGHT=13
export MAIN_MENU_MENU_HEIGHT=6

export CHAT_FEED_HEIGHT=30
export CHAT_FEED_WIDTH=110
export CHAT_INPUT_HEIGHT=8
export CHAT_INPUT_WIDTH=110

export BOARD_SELECTOR_HEIGHT=13
export BOARD_SELECTOR_WIDTH=100
export BOARD_SELECTOR_MENU_HEIGHT=5

export THREAD_SELECTOR_HEIGHT=40
export THREAD_SELECTOR_WIDTH=120
export THREAD_SELECTOR_MENU_HEIGHT=30

export THREAD_FEED_HEIGHT=40
export THREAD_FEED_WIDTH=120

export THREAD_TITLE_FORM_HEIGHT=10
export THREAD_TITLE_FORM_WIDTH=50

export THREAD_BODY_FORM_HEIGHT=20
export THREAD_BODY_FORM_WIDTH=120

export REPLY_FORM_HEIGHT=20
export REPLY_FORM_WIDTH=120

export USER_NAME_FORM_HEIGHT=10
export USER_NAME_FORM_WIDTH=50
# Config vars -- END #

main_controller
clear
exit 0
