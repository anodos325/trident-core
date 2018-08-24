#!/bin/sh
##############
# Quick script to probe the hardware and spit out the recommended driver for Xorg
##############

# First detect if the boottype is "UEFI" or not (legacy)
efi=`sysctl -nq machdep.bootmethod`
# Detect the vendor/device info for the graphics card
vendor=`pciconf -lv vgapci0 | grep vendor | cut -d \' -f 2`
device=`pciconf -lv vgapci0 | grep device | cut -d \' -f 2`
#  -- NOTE: For each match listed here, add the vendor -> driver logic below as well
MATCHES="nvidia:nvidia intel:intel innotek:vbox amd:amd vmware:vmware"
for match in ${MATCHES}
do
  echo "${vendor}" | grep -qi `echo ${match} | cut -d : -f 1`
  if [ $? -eq 0 ] ; then
    vendor_detected=`echo ${match} | cut -d : -f 2`
    break
  fi
done

#Now determine the driver based on the detected vendor
if [ "${vendor_detected}" = "intel" ] ; then
  if [ "${efi}" = "UEFI" ] ; then
    driver="modesetting intel"
  else
    driver="intel"
  fi

elif [ "${vendor_detected}" = "nvidia" ] ; then
  driver="nvidia nv"

elif [ "${vendor_detected}" = "vbox" ] ; then
  driver="vboxvideo"

elif [ "${vendor_detected}" = "amd" ] ; then
  if [ "${efi}" = "UEFI" ] ; then
    driver="amdgpu"
  fi
  driver="${driver} radeon ati"

elif [ "${vendor_detected}" = "vmware" ] ; then
  driver="vmware"

fi

# Add the fallback drivers to the end of the list
if [ "${efi}" = "UEFI" ] ; then
  driver="${driver} scfb"
else
  driver="${driver} vesa"
fi

# Now find the first driver from the list that works and return that
for drv in ${driver}
do
  #Does the driver exist?
  if [ -e /usr/local/lib/xorg/modules/drivers/${drv}_drv.so ] ; then
    echo ${drv}
    exit 0
  fi
done

#If we got here - no driver could be found
exit 1
