#!/bin/bash

# USE THIS SCRIPT FOR BASIC SYSTEM STATUS DEBUG INFO

# load code software version
source /home/admin/_version.info

## get basic info (its OK if not set yet)
source /home/admin/raspiblitz.info
source /mnt/hdd/raspiblitz.conf

# for old nodes
if [ ${#network} -eq 0 ]; then
  echo "backup info: network"
  network="bitcoin"
  litecoinActive=$(sudo ls /mnt/hdd/litecoin/litecoin.conf | grep -c 'litecoin.conf')
  if [ ${litecoinActive} -eq 1 ]; then
    network="litecoin"
  fi
fi

# for non final config nodes
if [ ${#chain} -eq 0 ]; then
  echo "backup info: chain"
  chain="test"
  isMainChain=$(sudo cat /mnt/hdd/${network}/${network}.conf 2>/dev/null | grep "testnet=0" -c)
  if [ ${isMainChain} -gt 0 ];then
    chain="main"
  fi
fi

clear
echo ""
echo "***************************************************************"
echo "* RASPIBLITZ DEBUG LOGS "
echo "***************************************************************"
echo "blitzversion: ${codeVersion}"
echo "chainnetwork: ${network} / ${chain}"
uptime
echo ""

echo "*** BLOCKCHAIN SYSTEMD STATUS ***"
sudo systemctl status ${network}d -n2 --no-pager
echo ""

echo "*** LAST BLOCKCHAIN ERROR LOGS ***"
echo "sudo journalctl -u ${network}d -b --no-pager -n8"
sudo journalctl -u ${network}d -b --no-pager -n8
cat /home/admin/systemd.blockchain.log | grep "ERROR" | tail -n -2
echo ""
echo "*** LAST BLOCKCHAIN 20 INFO LOGS ***"
pathAdd=""
if [ "${chain}" = "test" ]; then
  pathAdd="/testnet3"
fi
echo "sudo tail -n 20 /mnt/hdd/${network}${pathAdd}/debug.log"
sudo tail -n 20 /mnt/hdd/${network}${pathAdd}/debug.log
echo ""

echo "*** LND SYSTEMD STATUS ***"
sudo systemctl status lnd -n2 --no-pager
echo ""

echo "*** LAST LND ERROR LOGS ***"
echo "sudo journalctl -u lnd -b --no-pager -n12"
sudo journalctl -u lnd -b --no-pager -n12
cat /home/admin/systemd.lightning.log | grep "ERROR" | tail -n -1
echo ""
echo "*** LAST 30 LND INFO LOGS ***"
echo "sudo tail -n 30 /mnt/hdd/lnd/logs/${network}/${chain}net/lnd.log"
sudo tail -n 30 /mnt/hdd/lnd/logs/${network}/${chain}net/lnd.log
echo ""

if [ "${rtlWebinterface}" = "on" ]; then
  echo "*** LAST 20 RTL LOGS ***"
  sudo journalctl -u RTL -b --no-pager -n20
else
  echo "- RTL is OFF by config"
fi
echo ""

echo "*** HARDWARE TEST RESULTS ***"
showImproveInfo=0
if [ ${#undervoltageReports} -gt 0 ]; then
  echo "UndervoltageReports in Logs: ${undervoltageReports}"
  if [ ${undervoltageReports} -gt 0 ]; then
    showImproveInfo=1
  fi
fi
if [ -f /home/admin/stresstest.report ]; then
  sudo cat /home/admin/stresstest.report
  source /home/admin/stresstest.report
  if [ ${powerWARN} -gt 0 ]; then
      showImproveInfo=1
  fi
  if [ ${tempWARN} -gt 0 ]; then
      showImproveInfo=1
  fi
fi
if [ ${showImproveInfo} -gt 0 ]; then
  echo "IMPORTANT: There are some hardware issues with your setup."
  echo "'Run Hardwaretest' in main menu or: sudo /home/admin/05hardwareTest.sh"
fi
echo ""

echo "*** SYSTEM STATUS (can take some seconds to gather) ***"
sudo /home/admin/config.scripts/blitz.statusscan.sh
echo ""

echo "*** OPTION: SHARE THIS DEBUG OUTPUT ***"
echo "An easy way to share this debug output on GitHub or on a support chat"
echo "use the following command and share the resulting link:"
echo "/home/admin/XXdebugLogs.sh | nc termbin.com 9999"
echo ""
