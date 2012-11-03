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

# Create backup script
script="/tmp/$$shaeckup_script"
echo '#!/bin/bash' >>$script

# Query for paths to save
while [ "$paths" = "" ] ; do
    read -p "Enter the paths of the files and/or directories you wish to \
back up in one line, separated by spaces: " paths
done
echo 'tar czf /tmp/$$shaeckup_backup.tar.gz' $paths >>$script

# Query for encryption passphrase and path
while [ "$passphrase" = "" ] || [ ${#passphrase} -lt 20 ] ; do
    read -p "Enter the encryption passphrase. This phrase will be stored in a file \
which can only be read by the user $USER. Make sure you back up the file in a \
safe location to be able to decrypt the backups later. The passphrase must be \
at least 20 characters long." passphrase
done
while [ "$passphrase_path" = "" ] ; do
    read -p "Enter the path where the passphrase file is stored: " passphrase_path
done
echo $passphrase >$passphrase_path
chmod 700 $passphrase_path

# Insert encryption part into backup script
echo "aespipe -P $passphrase_path" '</tmp/$$shaeckup_backup.tar.gz >/tmp/$$shaeckup_backup.tar.gz.aes' >> $script

# Query for destination
echo "You must specify a destination, where the file will be copied via ssh."
while [ "$username" = "" ] ; do
    read -p "Username: " username
done
while [ "$host" = "" ] ; do
    read -p "Host: " host
done
while [ "$port" = "" ] ; do
    read -p "Port (usually 22): " port
done
while [ "$target_dir" = "" ] ; do
    read -p "Target directory: " target_dir
done

# Insert transmission part into backup script
echo "scp -P $port" '/tmp/$$shaeckup_backup.tar.gz.aes' \
$username@$host:$target_dir/backup.tar.gz.aes >>$script

# Query backup script storage location and move it there
while [ "$script_path" = "" ] ; do
    read -p "Backup script storage path (absolute): " script_path
done
mv $script $script_path
chmod a+x $script_path

# Check ssh pubkey authentication
if [ ! -e "~/.ssh/id_rsa.pub" ] ; then
    read -p  "It looks like you didn't generate a SSH key pair yet. This is \
essential for transmitting the backup. Do you want to do it now? [y/n] " yn
    if [ "$yn" = "y" ] ; then
        echo "Don't set a password for the keypair!"
        ssh-keygen
    else
        echo "Warning! You must take care of setting up public key \
authentication yourself before shaeckup backup works!"
        ssh_self_setup=yes
    fi
fi
if [ "$ssh_self_setup" = "" ] ; then
    read -p  "Your SSH public must be transferred to the backup destination. \
Should I do it for you? [y/n] " yn
    if [ "$yn" = "y" ] ; then
        scp -P $port ~/.ssh/id_rsa.pub $username@$host:.ssh/authorized_keys
    fi
fi

# Configure backup timetable
#TODO

# Write to crontab
crontab_tmp="/tmp/$$shaeckup_crontab_tmp"
crontab -l >$crontab_tmp
echo $CRON_LINE >>$crontab_tmp
crontab $crontab_tmp
rm $crontab_tmp
echo "Wrote job to crontab."

# Test run
read -p "Do you want to test the backup script? [y/n] " yn
if [ "$yn" = "y" ] ; then
    $script_path
fi
