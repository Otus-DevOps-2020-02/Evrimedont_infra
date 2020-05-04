#!/bin/bash

#gcloud compute instances create reddit-app \
#  --boot-disk-size=10GB \
#  --image-family ubuntu-1604-lts \
#  --image-project=ubuntu-os-cloud \
#  --machine-type=g1-small \
#  --tags puma-server \
#  --restart-on-failure \
#  --metadata-from-file startup-script=./startup_script.sh

gcloud compute firewall-rules create default-puma-server \
  --allow tcp:9292 \
  --target-tags=puma-server
