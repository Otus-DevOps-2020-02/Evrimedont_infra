#!/bin/bash
set -e

git clone -b monolith https://github.com/express42/reddit.git

cd reddit && bundle install

cp /tmp/puma.service /etc/systemd/system/puma.service

systemctl enable puma
