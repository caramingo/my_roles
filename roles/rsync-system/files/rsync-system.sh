#!/bin/sh

rsync -aAXv --exclude-from='/stuff/server/configs/confbackup/rsync-ignore-list.txt'  /  /backup-directory/week/
