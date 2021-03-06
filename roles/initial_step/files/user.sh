#!/bin/bash

set +e

a=0
showed_alert=0
showed_loading=false

# if not exists .maintenance_mode file then execute
if [ ! -f ".maintenance_mode" ];
then

  ##### set new hostname if hostname is set to default
  hostn=$(hostname)
  while [ $hostn = "thin" ];
  do
    newhost=""
    while [ -z $newhost ];
    do
      newhost=$(zenity --entry --title="Inserisci il nuovo hostname" --text="Hostname non settato, inserisci il nuovo hostname" --entry-text "$hostn")
    done
    pkexec bash -c 'sed -i "s/$0/$1/g" /etc/hosts; sed -i "s/$0/$1/g" /etc/hostname; reboot' $hostn $newhost
    # zenity --notification --window-icon="info" --text="Nuovo hostname inserito!" 
    # pkexec reboot
  done

  while :
  do
    if ! $showed_loading;
    then
      sleep 10
      pqiv -t -i -f  /home/user/Picture/REV.gif &
      showed_loading=true
    fi
    # get active interface
    eths_dev=$(nmcli -t -f uuid,type,device c s --active | grep 802 | awk -F  ":" '{ print $3 }' | paste -s -d, -)
    if [ -z "$eths_dev" ];
    then     
      ((a+=1))
      if [ $a -ge 4 ]
      then
        if [ "$showed_alert" = 0 ];
        then
          showed_alert=1
          zenity --error --width=200 --text "Errore di rete, contattare l'ufficio ICT"
          showed_alert=0
        fi
      fi
    else
      # set current active interface for vino
      eths_uuid=$(nmcli -t -f uuid,type c s --active | grep 802 | awk -F  ":" '{ print "'\''" $1 "'\''" }' | paste -s -d, -)
      gsettings set org.gnome.settings-daemon.plugins.sharing.service:/org/gnome/settings-daemon/plugins/sharing/vino-server/ enabled-connections "[ $eths_uuid ]"

      vmware-view --nomenubar &
      #vmware-view &
      VMWARE_PID=$!
      
      # reset condition
      sleep 10
      pkill -9 pqiv
      showed_loading=false
      a=0

      wait

    fi
    sleep 15
  done
fi