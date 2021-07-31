#/usr/bin/env bash
for i in $( ifconfig | awk 'BEGIN{FS="\n"; RS=""} {print $1}' | cut -d":" -f1 )
do
    myIP=$( ifconfig $i | grep "inet " | awk '{print $2}' )
    if [ -n "$myIP" ]
    then
      echo "$i - $myIP"
    fi
done
