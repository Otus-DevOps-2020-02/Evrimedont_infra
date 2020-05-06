#!/bin/bash

apt update
apt install -y ruby-full ruby-bundler build-essential

ruby -v

bundler -v

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xd68fa50fea312927
bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'

apt update
apt install -y mongodb-org

systemctl start mongod

systemctl enable mongod

systemctl status mongod

git clone -b monolith https://github.com/express42/reddit.git

cd reddit && bundle install

puma -d
