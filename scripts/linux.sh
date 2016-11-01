#!/bin/bash
function get_mountpoints {
  while read mountpoint; do
    echo "  - '$mountpoint'"
  done < <(cat /proc/mounts | grep -E "^/dev/$1 " | cut -d \  -f 2)
}
function is_removable {
  if [[ "$2" == "1" ]]; then
    return 1
  fi
  eval "$(udevadm info --query=property --export --export-prefix=UDEV_ --name="$1")"
  if [[ ( \
      "$UDEV_ID_DRIVE_FLASH_SD" == "1" && \
      "$UDEV_ID_DRIVE_MEDIA_FLASH_SD" == "1" \
      ) || "$UDEV_ID_BUS" == "usb" ]];  then
    return 1
  else
    return 0
  fi
}
while read line; do
  eval "$line"
  echo "device: /dev/$NAME"
  echo "description: \"$(echo $MODEL | sed -e 's/^\s+|\s+$//g')\""
  echo "size: $SIZE"
  echo "mountpoints: "
  get_mountpoints "$NAME"
  echo "raw: /dev/$NAME"
  if [[ $RO == 0 ]]; then
    echo "protected: False"
  else
    echo "protected: True"
  fi
  if is_removable "$NAME" $RM; then
    echo 'system: True'
  else
    echo 'system: False'
  fi
  if [[ "$TYPE" == "disk" ]]; then
    echo 'disk: True'
  else
    echo 'disk: False'
    echo "parent: /dev/$PKNAME"
  fi
  echo ''
done < <(lsblk -P -n -b --output NAME,KNAME,LABEL,TYPE,SIZE,PHY-SEC,PARTTYPE,FSTYPE,PKNAME,MODEL,RO,RM | sed -e 's/PHY-SEC/PHY_SEC/')
