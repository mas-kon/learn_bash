#/usr/bin/env bash
for i in $( lsblk | grep disk | awk '{print $1}' )
do 
  echo $i
done