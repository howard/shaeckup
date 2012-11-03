#!/bin/bash

echo "shaeckup (the unnaturally painful fusion of shell, AES, and backup) lets \
you send encrypted backups of your files to remote computers automatically. \
Follow the steps to set this up. No root privileges and daemons required!\n"

echo "In most cases, you should use incremental backups (e.g. using rsync) \
instead of shaeckup, because you save lots of transferred data. Use shaeckup \
if you need to back up sensitive data on a less trusted server. Remember: \
shaeckup always transfers all files. Only use if absolutely necessary.\n"

echo "Checking system requirements..."
which tar       >/dev/null 2>&1 || { echo >&2 '"tar" must be installed!'; exit 1; }
which aespipe   >/dev/null 2>&1 || { echo >&2 '"aespipe" must be installed!'; exit 1; }
which scp       >/dev/null 2>&1 || { echo >&2 '"scp" must be installed!'; exit 1; }
echo "All system requirements are fulfilled.\n"







# Modify crontab
CRONTAB_TMP="/tmp/$$shaeckup_crontab_tmp"
crontab -l >$CRONTAB_TMP
echo $CRON_LINE >>$CRONTAB_TMP
crontab $CRONTAB_TMP
rm $CRONTAB_TMP
echo "Wrote job to crontab."
