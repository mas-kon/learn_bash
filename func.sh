zzgrep () {
if [ $# -lt 2 ]
then
    echo "No argument."
else
  if [ -f $1 ]
  then
    mkdir $PWD/temp 
    tar -C "$PWD/temp" -xvzf $1 > /dev/null
    flist=$(find  $PWD/temp -type f )
    for file in $flist
    do
        if  grep -w $2 $file > /dev/null 2>&1 
        then
            echo "OK"
        else
            echo "FAIL"
        fi
    done
    rm -Rf temp
  else 
      echo "No file!"
  fi
fi
}
