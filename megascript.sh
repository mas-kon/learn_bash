#!/usr/bin/env bash

#Проверяем юзера, от которого запустили скрипт
#if [ "$(whoami)" != 'root' ]; then
if [ $(id -u) -ne 0 ]
 then
    echo "Plese, use sudo $0" # Если не от root, то ругаемся
else # Если от root - то продолжаем

# ======================== Начало основного цикла скрипта =============================

# Оформление начала и конца вывода
my_beg_echo () { 
  echo -e "\n\n======================================================\n" 
}
my_end_echo () { 
  echo -e "\n======================================================\n\n" 
}

# Определяем платформу, на которой запущена система.
if [[ -z $(dmidecode -s system-product-name 2>/dev/null) ]]
then
  VIRT="lxc"
else
  VIRT=$(dmidecode -s system-product-name 2>/dev/null)
fi

# Выводит краткую помощь по использованию скрипта
myhelp () {
  my_beg_echo
  cat << EOF
    Usage:
    $0 [OPTIONS] 

    OPTIONS:
    -p, --proc - работа с директорией /proc
    -c, --cpu - информация о процессоре
    -m, --memory - работа с памятью
    -d, --disks - работа с дисками
    -n, --network - работа с сетью
    -la, --loadaverage - вывод средней нагрузки на систему
    -k, --kill - работа с процессами
    -i, --info - информация о системе
    -h, --help - это сообщение

    For save result please use $0 [OPTIONS] > file_name.txt
EOF
  my_end_echo
}

# Работа с процессами
my_proc () {
  if [ -z "$2" ]
    then
        find /proc -type f -name "*" -maxdepth 1 | awk -F"/" '{print $3}' | sort
        my_beg_echo
        echo "For detail info please use -p cpuinfo, -p meminfo etc."
        my_end_echo
    else
        cat /proc/$2
  fi
}


# Работа с памятью
my_memory () {
  if [ -z "$2" ]
    then
          /usr/bin/free -h 
          my_beg_echo
          echo "For detail info please use -m total, -m used etc. "
          my_end_echo
  else
    while [ -n "$2" ]
      do
        case "$2" in
          total) echo "Total memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $2}'`" ;;
          used) echo "Used memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $3}'`" ;;
          free) echo "Free memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $4}'`" ;;
          shared) echo "Shared memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $5}'`" ;;
          buff) echo "Buff/cache memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $6}'`" ;;
          cache) echo "Buff/cache memory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $6}'`" ;;
          available) echo "Available mamory `/usr/bin/free -h | awk 'BEGIN{FS="\n"; RS=""} {print $2}' | awk '{print $7}'`" ;;
        esac
      shift
      done
  fi
}

# Вывод всех интерфейсов с IP-адресами
my_network_ip () {
  for i in $( ifconfig | awk 'BEGIN{FS="\n"; RS=""} {print $1}' | cut -d":" -f1 )
    do 
        myIP=$( ifconfig $i | grep "inet " | awk '{print $2}' )
        if [ -n "$myIP" ]
        then
          echo "$i - $myIP"
        fi
    done
}

# Вывод всех интерфейсов без IP-адресов
my_network_noip () {
   for i in $( ifconfig | awk 'BEGIN{FS="\n"; RS=""} {print $1}' | cut -d":" -f1 )
    do 
        myIP=$( ifconfig $i | grep "inet " | awk '{print $2}' )
        if [ -z "$myIP" ]
        then
          echo "$i"
        fi
    done
}

# Работа с сетевыми интерфейсами
my_network () {
  if [[ -f /sbin/ifconfig || -f /usr/sbin/ifconfig ]]
    then
      if [ -z "$2" ]
        then
          ifconfig
          my_beg_echo
          echo "For detail info please use:"
          echo " -n ip - for interfaces with ip address "
          echo " -n noip - for interfaces without ip address"
          echo " -n list - for list of interfaces"
          my_end_echo
      else
        while [ -n "$2" ]
            do
              case "$2" in
                ip) my_network_ip ;;
                noip) my_network_noip ;;
                list) ifconfig | awk 'BEGIN{FS="\n"; RS=""} {print $1}' | cut -d":" -f1 ;;
              esac
            shift
            done
      fi
  else
    echo "Please, install net-tools package."
  fi
}

# Смотрим Load average
my_la () {
  w | grep "load average" | sed 's/,//g' | awk '{print $8 " " $9 " " $10  " " $11 " "  $12}'
}


# Детальная информация о диске
my_detail_disk () {
  if [ -f /usr/sbin/fdisk ] || [ -f /sbin/fdisk ]
    then
      fdisk -l /dev/$1
    else 
      echo "Command "fdisk" not found"
  fi
}

# Работа с дисками
my_disks () {
  if [ -z "$2" ]
    then
      df -h | grep -v tmp | grep -v none | grep -v snap | grep -v " /dev"
      if [[ "$1" == "-d" || "$1" == "--disks" ]]
        then
          my_beg_echo
          echo "For detail info please use:"
          echo " -d detail DISK (sda, sdb etc) - detailed information about disk."
          my_end_echo
      fi
    else
      while [ -n "$2" ]
        do
          case "$2" in
            detail) if [[ "$VIRT" != "lxc" ]]
              then 
                my_detail_disk $3 
              else
                echo "This is LXC-container. No phisical disk." 
              fi ;;
          esac
        shift
        done
  fi  
}

# Работа с процессами
my_kill () {
  if [ -f /usr/bin/pidstat ]
    then
      if [ -z "$2" ]
        then
          pidstat -H | awk '{print $3 "\t " $10}' | sed 1,2d | sort -k2
          my_beg_echo
          echo "For detail info please use:"
          echo " -k kill PID - kill process with PID"
          echo " -k detail PID - details for process with PID"
          my_end_echo
        else
          while [ -n "$2" ]
            do
              case "$2" in
              kill) kill -9 $3 ;;
              detail) pidstat -p $3  ;;
              esac
            shift
          done
      fi
    else 
      my_beg_echo
      echo "Please install \"sysstat\" package."
      my_end_echo
  fi
}

# Смотрим на процессор
my_cpu () {
  local mod_cpu=$(cat /proc/cpuinfo | grep -E "(model name)" | cut -d":" -f2 | uniq )
  local num_cpu=$(cat /proc/cpuinfo | grep -E "(model name)" | uniq -c | awk '{print $1}' )
  echo "Model of CPU - $mod_cpu "
  echo "Number of CPU - $num_cpu"
  echo "Architecture - `uname -a | awk '{print $(NF-1)}'`"
}

# Общая информация о системе
my_info () {
  my_beg_echo
  if [[ "$VIRT" != "lxc" ]]
    then 
      dmidecode --type system | sed '1,5d' | sed '10,$d' | sed 's/^[ \t]*//'
    else
      echo "This is LXC-container or WSL"
  fi
  my_distr
  my_cpu
  my_disks
  my_end_echo
}

my_distr () {
  cat /etc/*release | grep PRETTY_NAME | sed 's/^PRETTY_NAME=//' | sed 's/\"//g'
}


# Проверяем аргументы программы
  if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]
  then
      echo "Please, use -h or --help option for help."
  else
      while [ -n "$1" ]
      do
        case "$1" in
          -h | --help ) myhelp ;;
          -p | --proc) my_proc $1 $2 ;;
          -m | --memory) my_memory $1 $2 ;;
          -n | --network) my_network $1 $2 ;;
          -d | --disk) my_disks $1 $2 $3;;
          -la) my_la ;;
          -k | --kill) my_kill $1 $2 $3;;
          -c | --cpu) my_cpu ;;
          -i | --info) my_info ;;
        esac
      shift 
      done
  fi

# ======================== Конец основного цикла скрипта =============================
fi
