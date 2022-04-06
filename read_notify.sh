#!/usr/bin/env bash

# This script looks in the directories that you specify with "library"
# After that, it counts the files in all subdirectories, and insert
# the results in a sqlite database. If any new files has been added
# since the last run, a push message will be sent.

# I made it to send notifications when new volumes of comics/manga
# have been added, but it can be used for anything I guess.

# Be careful with special characters. Should work pretty good,
# but I give no guarantees.

# The file structure should be something like this:
# "/path/one/manga name/chapter one.cbz"

######################################################################
# Config folder path, were to store the database.
######################################################################
config_path="/opt/read_notify"

######################################################################
# Library folder paths, you can add as many as you want.
######################################################################
library=( "/path/one" "/path/two" "/path/three" )

######################################################################
# Notifications
# Fill in the credentials for the service you want to use, or both.
######################################################################

# ntfy.sh
ntfy_url="https://ntfy.sh/mytopic"
ntfy_title="A title"
ntfy_added_tag="heavy_plus_sign"
ntfy_deleted_tag="heavy_minus_sign"
ntfy_username=""
ntfy_password=""

# Pushover
pushover_app_token=""
pushover_user_token=""

######################################################################
# What should the notifications look like?
# For example: "2 chapter(s) of foldername added" will be sent.
######################################################################
push_type="volume(s) of"
push_added="added"
push_deleted="deleted"

######################################################################
# Script starts here
######################################################################

dbpath="$config_path/data.db"

if ! sqlite3 --version &> /dev/null ;
then
  echo "You need sqlite installed for this script."
  exit 1
fi

check_lock() {
  if [ -f /tmp/read_notify.lock ];
  then
    echo "read_notify.sh is already running, exiting..."
    exit 0
  fi

  trap "rm -f /tmp/read_notify.lock ; rm -f /tmp/read_notify_added.tmp ; rm -f /tmp/read_notify_deleted.tmp ; exit" INT TERM EXIT
  touch /tmp/read_notify.lock
}

check_chapters() {

  for tbl in "${library[@]}"; do
    if [ -d "$tbl" ]; then
      # echo "$tbl"
      tbl_name=$( echo "$tbl" | tr / _  | sed 's/[^[:alnum:]_]//g' )
      sqlite3 "$dbpath" "CREATE TABLE IF NOT EXISTS $tbl_name (name CHAR NOT NULL PRIMARY KEY, realname CHAR, chapters INT );"
      IFS=$'\n'
      for dir in $(find $tbl -mindepth 1 -maxdepth 1 -type d -printf '%P\n' ); do
        name=$( echo "$dir" | tr -s '[:blank:]' '_' | sed 's/[^[:alnum:]_]//g' )
        oldnr=$( sqlite3 "$dbpath" "SELECT chapters FROM $tbl_name WHERE name=\"$name\";" 2>/dev/null )
        newnr=$( ls -1q "$tbl"/"$dir" | wc -l )
        if [ -z "$oldnr" ]; then
          oldnr="0"
        fi
        if [ -z "$newnr" ]; then
          newnr="0"
        fi
        if [ "$newnr" -gt "$oldnr" ]; then
          chap=$( expr $newnr - $oldnr )
          echo "$chap $push_type $dir $push_added" >> /tmp/read_notify_added.tmp
        elif [ "$newnr" -lt "$oldnr" ]; then
          chap=$( expr $oldnr - $newnr )
          echo "$chap $push_type $dir $push_deleted" >> /tmp/read_notify_deleted.tmp
        fi

        sqlite3 "$dbpath"  "INSERT OR IGNORE INTO $tbl_name (name,realname,chapters) VALUES (\"$name\",\"$dir\",\"$newnr\"); UPDATE $tbl_name SET chapters = $newnr WHERE name=\"$name\""
      done
      unset IFS
    fi
  done
}

check_push() {
  # Send push message
  if [ -f "$push_file" ]; then
    if [ -n "$ntfy_url" ]; then
      if [ -z "$ntfy_password" ]; then
        ntfy_auth=""
      else
        ntfy_auth="-u $ntfy_username:$ntfy_password"
      fi
      curl -s $ntfy_auth -H tags:"$ntfy_tag" -H "X-Title: $ntfy_title" -d "$push_message" $ntfy_url > /dev/null
    fi
    if [ -n "$pushover_app_token" ]; then
      curl -s -F "token=$pushover_app_token" -F "user=$pushover_user_token" -F "message=$push_message" https://api.pushover.net/1/messages
    fi
  fi
}

check_push_added() {
  push_file="/tmp/read_notify_added.tmp"
  push_message=$( cat /tmp/read_notify_added.tmp 2>/dev/null )
  ntfy_tag="$ntfy_added_tag"
  check_push
}

check_push_deleted() {
  push_file="/tmp/read_notify_deleted.tmp"
  push_message=$( cat /tmp/read_notify_deleted.tmp 2>/dev/null )
  ntfy_tag="$ntfy_deleted_tag"
  check_push
}

cleanup() {
  # Clean up tables
  libr_path=()
  for libr in "${library[@]}"; do
    if [ -d "$libr" ]; then
      libr_path+=("$(echo $libr | tr / _ | sed 's/[^[:alnum:]_]//g')")
    fi
  done
  for tbl in $(sqlite3 "$dbpath" ". tables"); do
    if [[ ! "${libr_path[*]}" =~ ${tbl} ]]; then
      sqlite3 "$dbpath" "DROP TABLE $tbl;"
    fi
  done

  # Clean up records
  for libr in "${library[@]}"; do
    if [ -d "$libr" ]; then
      IFS=$'\n'
      for dir in $(find $libr -mindepth 1 -maxdepth 1 -type d -printf '%P\n' ); do
        libr_name+=$( echo "$dir" | tr -s '[:blank:]' '_' | sed 's/[^[:alnum:]_]//g' )
      done
      unset IFS
      tbl_name=$(echo "$libr" | tr / _ | sed 's/[^[:alnum:]_]//g')
      for name in $(sqlite3 "$dbpath" "SELECT name FROM $tbl_name"); do
        if [[ ! "${libr_name[*]}" =~ ${name} ]]; then
          realname=$( sqlite3 "$dbpath" "SELECT realname FROM $tbl_name WHERE name = \"$name\"" )
          sqlite3 "$dbpath" "DELETE FROM $tbl_name WHERE name = \"$name\""
          echo "$realname $push_deleted" >> /tmp/read_notify_deleted.tmp
        fi
      done
    fi
  done
}

sqlite3 "$dbpath" "VACUUM;"

check_lock
check_chapters
cleanup
check_push_added
check_push_deleted
rm -f /tmp/read_notify_added.tmp 2>/dev/null
rm -f /tmp/read_notify_deleted.tmp 2>/dev/null

rm -f /tmp/read_notify.lock

exit 0
