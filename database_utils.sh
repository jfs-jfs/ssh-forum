#!/bin/bash


### Globals
query_result=""
save_result=0
query_error=0

### Functions

function reset_db()
{
    query_result=""
    save_result=0
    query_error=0
}

function select_query()
{

    if [ $# -ne 1 ];then
        echo -e "Wrong number of parameters in selec_query"; exit 1;
    fi

    local query="$1"
    # echo -e "$query";read

    if [ $save_result -eq 0 ]; then
        query_result=$(mysql -B -u$USER -p$PASS $BDNAME -e "$query")
    else
        mysql -B -u$USER -p$PASS $BDNAME -e "$query"
    fi

    # echo -e "res:\n$query_result";read
}

function other_query()
{
    if [ $# -ne 1 ];then
        echo -e "Wrong number of parameters in other_queryt"; exit 1;
    fi

    local query="$1"
    # echo -e "$query";read
    mysql -B -u$USER -p$PASS $BDNAME -e "$query" || query_error=1
    # read
}