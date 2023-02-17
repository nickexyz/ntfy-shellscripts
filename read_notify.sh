#!/usr/bin/env bash

# This script looks in the directories that you specify with "library"
# After that, it counts the .cbz files in all subdirectories, and inserts
# the results in a sqlite database. If any new files has been added
# since the last run, a push message will be sent.

# I made it to send notifications when new chapters of comics/manga
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
# Do you want to be notified if there is a gap in the numbering?
# Usually indicates a missing chapter/volume.
#
# When a file is added or deleted, it also checks for gaps.
# 1 = On, 0 = Off
#
# To run a search for the whole library:
# ./read_notify search_missing
#
# If a series is named like this:
# Chapter 1.cbz
# Chapter 2.cbz
# Chapter 3.1.cbz
# Chapter 3.2.cbz
# The script will think that Chapter 3 is missing.
# Simply create a ignore file, to manually ignore the "gap".
# Chapter 1.cbz
# Chapter 2.cbz
# Chapter 3.ignore
# Chapter 3.1.cbz
# Chapter 3.2.cbz
#
# If you want to ignore the whole directory, create an .ignore_gaps file:
# /path/to/manga/.ignore_gaps
######################################################################
find_missing="0"

######################################################################
# Notifications
# Fill in the credentials for the service you want to use, or both.
######################################################################

# ntfy.sh
ntfy_url="https://ntfy.sh/mytopic"
ntfy_title="A title"
ntfy_added_tag="heavy_plus_sign"
ntfy_deleted_tag="heavy_minus_sign"
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username=""
ntfy_password=""
ntfy_token=""
# Leave empty if you do not want an icon.
ntfy_icon=""

# Pushover
pushover_app_token=""
pushover_user_token=""

######################################################################
# What should the notifications look like?
# For example: "2 chapter(s) of foldername added" will be sent.
######################################################################
push_type="chapters(s) of"
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
      for di in "$tbl"/*/ ; do
        # Remove path and trailing slash
        dir=$( echo "$di" | sed "s|$tbl/||g" | sed 's:/*$::' )

        name=$( echo "$dir" | tr -s '[:blank:]' '_' | sed 's/[^[:alnum:]_]//g' )
        oldnr=$( sqlite3 "$dbpath" "SELECT chapters FROM $tbl_name WHERE name=\"$name\";" 2>/dev/null )
        newnr=$( ls -1q "$tbl"/"$dir"/*.cbz | wc -l )
        if [ -z "$oldnr" ]; then
          oldnr="0"
        fi
        if [ -z "$newnr" ]; then
          newnr="0"
        fi
        if [ "$newnr" -gt "$oldnr" ]; then
          chap=$( expr $newnr - $oldnr )
          echo "$chap $push_type $dir $push_added" >> /tmp/read_notify_added.tmp
          if [[ "$find_missing" == "1" ]]; then
            find_gaps
          fi
        elif [ "$newnr" -lt "$oldnr" ]; then
          chap=$( expr $oldnr - $newnr )
          echo "$chap $push_type $dir $push_deleted" >> /tmp/read_notify_deleted.tmp
          if [[ "$find_missing" == "1" ]]; then
            find_gaps
          fi
        fi

        sqlite3 "$dbpath"  "INSERT OR IGNORE INTO $tbl_name (name,realname,chapters) VALUES (\"$name\",\"$dir\",\"$newnr\"); UPDATE $tbl_name SET chapters = $newnr WHERE name=\"$name\""
      done
    fi
  done
}

check_push() {
  # Send push message
  if [ -f "$push_file" ]; then
    if [ -n "$ntfy_url" ]; then
      if [[ -n $ntfy_password && -n $ntfy_token ]]; then
        echo "Use ntfy_username and ntfy_password OR ntfy_token"
        exit 1
      elif [ -n "$ntfy_password" ]; then
        ntfy_base64=$( echo -n "$ntfy_username:$ntfy_password" | base64 )
        ntfy_auth="Authorization: Basic $ntfy_base64"
      elif [ -n "$ntfy_token" ]; then
        ntfy_auth="Authorization: Bearer $ntfy_token"
      else
        ntfy_auth=""
      fi
      curl -H "$ntfy_auth" -H tags:"$ntfy_tag" -H "X-Icon: $ntfy_icon" -H "X-Title: $ntfy_title" -d "$push_message" $ntfy_url > /dev/null
    fi
    if [ -n "$pushover_app_token" ]; then
      curl -s -F "token=$pushover_app_token" -F "user=$pushover_user_token" -F "message=$push_message" https://api.pushover.net/1/messages
    fi
  fi
}

check_push_added() {
  push_file="/tmp/read_notify_added.tmp"
  # Replace _ with space.
  sed -i 's/_/ /g' /tmp/read_notify_added.tmp 2>/dev/null
  push_message=$( cat /tmp/read_notify_added.tmp 2>/dev/null )
  ntfy_tag="$ntfy_added_tag"
  check_push
}

check_push_deleted() {
  push_file="/tmp/read_notify_deleted.tmp"
  # Replace _ with space.
  sed -i 's/_/ /g' /tmp/read_notify_added.tmp 2>/dev/null
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
      readarray -d '\n' libr_name < <(find "$libr" -mindepth 1 -maxdepth 1 -type d -printf '%P\n')
      for arr_line in "${libr_name[@]}"; do
        libr_name_clean+=$( echo "$arr_line" | tr -s '[:blank:]' '_' | sed 's/[^[:alnum:]_]//g' )
      done
      tbl_name=$(echo "$libr" | tr / _ | sed 's/[^[:alnum:]_]//g')
      for name in $(sqlite3 "$dbpath" "SELECT name FROM $tbl_name"); do
        if [[ ! "${libr_name_clean[*]}" =~ ${name} ]]; then
          realname=$( sqlite3 "$dbpath" "SELECT realname FROM $tbl_name WHERE name = \"$name\"" )
          sqlite3 "$dbpath" "DELETE FROM $tbl_name WHERE name = \"$name\""
          echo "$realname $push_deleted" >> /tmp/read_notify_deleted.tmp
        fi
      done
    fi
  done
}

find_gaps() {
  ls -1 "$tbl"/"$dir"/{*.cbz,*.ignore} > /tmp/read_notify_missing.first.tmp 2>/dev/null
  oIFS=$IFS
  while IFS="" read -r wholeline || [ -n "$p" ] ; do
    rm -f /tmp/read_notify_missing.work.tmp 2>/dev/null
    only_name=${wholeline##*/}
    # Echo line, split numbers and chars on different lines, remove everything except numbers, remove leading 0s.
    printf '%s\n' "$only_name" | grep -Eo '[[:alpha:]]+|[0-9]+' | grep -x '[0-9][0-9]*' | sed -e 's:^0*::' | sed '/^\s*$/d' >> /tmp/read_notify_missing.work.tmp
    number_last=$( cat /tmp/read_notify_missing.work.tmp | tail -n 1 )
    number_lines=$( cat /tmp/read_notify_missing.work.tmp | wc -l )
    # See if we can find the string Chapter, and grab the number from there.
    if echo "$only_name" | grep -q "[Cc][Hh][Aa][Pp][Tt][Ee][Rr]"; then
      # Check if Chapter is in the name more than once. The right one is probably the first in that case.
      if echo "$only_name" | grep -q '\('"Chapter"'\).*\1' ; then
        only_name_minus_chapter=$( echo "$only_name" | sed -E 's/(.*)Chapter/\1NOPE/' )
        new_chapnr=$( echo "$only_name_minus_chapter" | sed -nr '/[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\._ ][0-9]+/ s/.*[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\._ ]+([0-9]+).*/\1/p' )
        # If empty, use the old nr.
        if [ -z "$new_chapnr" ]; then
          echo "$number_last" >> /tmp/read_notify_missing.second.tmp
        else
          echo "$new_chapnr" >> /tmp/read_notify_missing.second.tmp
        fi
      else
        new_chapnr=$( echo "$only_name" | sed -nr '/[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\._ ][0-9]+/ s/.*[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\._ ]+([0-9]+).*/\1/p' )
        if [ -z "$new_chapnr" ]; then
          echo "$number_last" >> /tmp/read_notify_missing.second.tmp
        else
          echo "$new_chapnr" >> /tmp/read_notify_missing.second.tmp
        fi
      fi
    else
      # Check if there are more than two numbers, which indicates that there are numbers in the chapter name.
      if [ "$number_lines" -gt "2" ]; then
        new_chapnr=$( echo "$only_name" | sed -nr '/[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\. ][0-9]+/ s/.*[Cc][Hh][Aa][Pp][Tt][Ee][Rr][\. ]+([0-9]+).*/\1/p' )
        # If empty, use the old nr.
        if [ -z "$new_chapnr" ]; then
          echo "$number_last" >> /tmp/read_notify_missing.second.tmp
        else
          echo "$new_chapnr" >> /tmp/read_notify_missing.second.tmp
        fi
      else
        echo "$number_last" >> /tmp/read_notify_missing.second.tmp
      fi
    fi
  done < /tmp/read_notify_missing.first.tmp
  IFS=$oIFS
  # Remove duplicates and sort
  if [ -f "/tmp/read_notify_missing.second.tmp" ]; then
    cat /tmp/read_notify_missing.second.tmp | awk '!seen[$0]++' | sort -V > /tmp/read_notify_missing.second.tmp.1
    mv /tmp/read_notify_missing.second.tmp.1 /tmp/read_notify_missing.second.tmp
    seq $(head -n1 /tmp/read_notify_missing.second.tmp) $(tail -n1 /tmp/read_notify_missing.second.tmp) | grep -vwFf /tmp/read_notify_missing.second.tmp - >> /tmp/read_notify_missing.tmp
    # Chapter 1 should exist, so check for that specifically.
    if ! grep -qcE '^1([^0-9]|$)' /tmp/read_notify_missing.second.tmp ; then
      echo "1" >> /tmp/read_notify_missing.tmp
    fi
  fi
  rm -f /tmp/read_notify_missing.first.tmp
  rm -f /tmp/read_notify_missing.second.tmp
  if [ -s "/tmp/read_notify_missing.tmp" ]; then
    if [ -f "/tmp/read_notify_added.tmp" ]; then
      echo "These $push_type are missing from $dir" >> /tmp/read_notify_added.tmp
      cat /tmp/read_notify_missing.tmp >> /tmp/read_notify_added.tmp
    else
      echo "These $push_type are missing from $dir" >> /tmp/read_notify_deleted.tmp
      cat /tmp/read_notify_missing.tmp >> /tmp/read_notify_deleted.tmp
    fi
    rm -f /tmp/read_notify_missing.tmp
  fi
}


check_lock

if [[ "$1" == "search_missing" ]]; then
  for tbl in "${library[@]}"; do
    if [ -d "$tbl" ]; then
      for di in "$tbl"/*/ ; do
        # Remove path and trailing slash
        dir=$( echo "$di" | sed "s|$tbl/||g" | sed 's:/*$::' )
        if [ ! -f "$dir".ignore_gaps ] ; then
          find_gaps
        fi
      done
    fi
  done
  check_push_deleted
  rm -f /tmp/read_notify_added.tmp 2>/dev/null
  rm -f /tmp/read_notify_deleted.tmp 2>/dev/null
  rm -f /tmp/read_notify.lock
  exit 0
fi

sqlite3 "$dbpath" "VACUUM;"

check_chapters
cleanup
check_push_added
check_push_deleted
rm -f /tmp/read_notify_added.tmp 2>/dev/null
rm -f /tmp/read_notify_deleted.tmp 2>/dev/null

rm -f /tmp/read_notify.lock

exit 0

