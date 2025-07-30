#!/bin/bash

export LOG_DEBUG=0
export LOG_INFO=1
export LOG_ERROR=2

function log() {
  echo "$(date) :: $*" >>"$LOG_FILE"
}

function info() {
  if (("$LOG_LEVEL" <= "LOG_INFO")); then
    log "**INFO** :: $*"
  fi
}

function debug() {
  if (("$LOG_LEVEL" <= "$LOG_DEBUG")); then
    log "[[DEBUG]] :: $*"
  fi
}

function error() {
  if (("$LOG_LEVEL" <= "$LOG_ERROR")); then
    log "!!ERROR!! :: $*"
  fi
}
