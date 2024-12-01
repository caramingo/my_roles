#!/bin/sh

############################
# Skeleton file for backuper
############################

# server name
server_name="name_here.ivtek"

# defined below in "case"-section.
ruby_cmd="" # ruby path
dirs="" # config directories to backup
git_path="" # path to GIT

# variables
script_path="/stuff/server/configs/confbackup/backuper.rb" # current directory
dest_dir="/stuff/server/configs/backups" # local GIT repository
git_repo="http://gitlab.ivtek/configs/servers/${server_name}.git" # GIT repository


case `uname` in
    FreeBSD)
        ruby_cmd="/usr/local/bin/ruby"
        git_path="/usr/local/bin/git"
        dirs="--source-dir=/etc --source-dir=/usr/local/etc"
        ;;

    Linux)
        ruby_cmd="/usr/bin/ruby"
        git_path="/usr/bin/git"
        dirs="--source-dir=/etc"
        ;;
esac

# if GIT repository does not exists - this is first run.
# we need to init repository first.
if [ ! -d ${dest_dir}/.git ]; then
    printf "Seems like repository does not exist. Initializing...\r\n"
    cwd=`pwd`
    cd ${dest_dir}
    ${git_path} clone ${git_repo} ./
    cd ${cwd}
fi

${ruby_cmd} ${script_path} --verbose ${dirs} --dest-dir=${dest_dir} --git-path=${git_path} --git-repo=${git_repo}
