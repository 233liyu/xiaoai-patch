#!/bin/sh

echo "[*] Deleting run services"
for SERVICE in \
  work_day_sync_service xiaomi_dns_server mediaplayer messagingagent \
  wifitool mitv-disc miio pns mibrain_service mico_ai_crontab mico_ir_agent \
  nano_httpd pns_ubus_helper quickplayer voip mdplay mibt_mesh_proxy \
  mico_helper mico_voip_service mico_voip_ubus_helper mico_voip_ubus_service \
  mico_aivs_lab didiagent aw_upgrade_autorun miot_agent miio_mpkg idmruntime \
  statpoints_daemon alarm notify dlnainit touchpad sound_effect linein \
  volctl cmcc_andlink cmcc_dm telecom_plugin telecom_zhejiang; do

  rm -vf $ROOTFS/etc/rc.d/S??${SERVICE}
done

echo "[*] Deleting unused config cmcc"
rm -vf $ROOTFS/etc/config/cmcc
rm -rvf $ROOTFS/etc/tts
rm -vf $ROOTFS/etc/miaudio.conf

echo "[*] Removing cronjobs"
shasum $ROOTFS/etc/crontabs/*
rm -rvf $ROOTFS/etc/crontabs
ln -svf /data/etc/crontabs $ROOTFS/etc/crontabs
