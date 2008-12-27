#!/bin/bash  
echo "RUNNING"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games        
erl -noshell -pa "/home/daleharvey/www/econnrefused.com/logviewer" -eval "chat_log_util:start(last)" -s init stop
