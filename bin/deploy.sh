#!/bin/bash
HOME_DIR=/home/staging
USER=staging
PROJECT_DIR=$HOME_DIR/project
if [ $# -lt 1 ]; then
    echo "Usage: deploy.sh <branch>"
    exit 1
fi
BRANCH=$PROJECT_DIR/$1
BRANCH_PORT=$(grep $1 $HOME_DIR/conf/nginx-map.conf|cut -d " " -f 2)
if [ -z $BRANCH_PORT ];then
    echo "No port found. Update nginx-map.conf"
    exit 1
fi
BRANCH_PORT=${BRANCH_PORT%?}
if [ ! -e $PROJECT_DIR/$1 ]; then
    mkdir $BRANCH
    cd $BRANCH
    git clone -b $1 git@github.com:ourteam/project.git .
else
    cd $BRANCH
    git reset --hard
    git pull origin $1
fi
if [ ! -e $HOME_DIR/venv ]; then
    virtualenv $HOME_DIR/venv
fi
source $HOME_DIR/venv/bin/activate
pip install -r requirements/requirements_staging.txt
cat << _EOF_ > $HOME_DIR/uwsgi/$1.ini
[uwsgi]
socket = 127.0.0.1:$BRANCH_PORT
master = 1
processes = 2
threads = 1
uid = $USER
gid = $USER
chdir = $BRANCH/flask-app
pp = $BRANCH/flask-app
logto = $HOME_DIR/log/$1.log
module = run
callable = app
virtualenv = $HOME_DIR/venv
_EOF_

