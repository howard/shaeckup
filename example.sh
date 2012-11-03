#!/bin/bash
tar czf /tmp/$$shaeckup_backup.tar.gz /home/user/dev /home/user/docs
aespipe -P /home/user/.shaeckup/test_key </tmp/$$shaeckup_backup.tar.gz >/tmp/$$shaeckup_backup.tar.gz.aes
scp -P 22 /tmp/$$shaeckup_backup.tar.gz.aes backup_user@holo.codexfons.net:/home/backup_user/backup.tar.gz.aes
