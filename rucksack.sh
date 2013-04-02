#!/bin/sh

# rucksack: a cheeky script that uses unionfs to mount a local and remote pkg cache together on your machine

. /etc/rc.conf
. /etc/rc.d/functions

t_cache="/var/cache/pacman/pkg"

[ -z $3 ] && echo "usage: $0 {-start|-stop} local_cache remote_cache target_cache" && exit 1

# modprobe unionfs
[ "$(lsmod | grep unionfs)" ] || modprobe -f unionfs


[ -z $l_cache ] && l_cache="$2"
[ -z $r_cache ] && r_cache="$3"
[ -z $t_cache ] && t_cache="$4"

check_n_mount()
{
      eval cache=\$$1
      if [ "$(mount | grep "on $cache")" ] ; then
        continue
      elif [ "$(</etc/fstab grep $cache)" ] ; then
        status "Mounting $2 cache" && mount "$cache"
      elif [ "$2" == "local" ]; then
        [ ! -d "${cache}" ] && fail "$2 not found"
      fi
}

check_n_umount()
{
    eval cache=\$$1
    if [ "$(mount | grep "on $cache")" ] ; then
      status "Unmounting $2 cache" &&  umount "$cache"
      [ $? -ne 0 ]
    fi
}

fail()
{
    printhl "$1"
    exit 1
}

case "$1" in
  -start)
    # check $l_cache is mounted
    check_n_mount l_cache local
    
    # check $r_cache is mounted
    check_n_mount r_cache remote
    
    # check $t_cache isn't mounted
    if [ "$(mount | grep "on $t_cache")" ] ; then
      fail "$t_cache already mounted"
    else
      if [ -d "${t_cache}" ]; then
        status "Mounting pacman cache" && mount -t unionfs -o dirs=${l_cache}=rw:${r_cache}=ro unionfs ${t_cache}
      fi
    fi
    ;;

  -stop)
    # check pacman cache is mounted and umount
    check_n_umount t_cache pacman

    # check remote cache is mounted and umount
    check_n_umount r_cache remote
    
    if [ "$(mount | grep "on $l_cache")" ] ; then
      status "Unmounting local cache" && umount "${1}"
    fi
    ;;
  *)
    echo "usage: $0 {-start|-stop} local_cache remote_cache target_cache"  
esac
