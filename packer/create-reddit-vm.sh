#!/bin/bash

# Создаём image reddit-base при помощи packer
#packer build -var-file=variables.json ubuntu16.json

# Создаём image reddit-full при помощи packer
packer build -var="project_id=$GCP_PROJECT_ID" immutable.json

# Удаляем существующий инстанс reddit-app
gcloud compute instances delete --quiet reddit-app

gcloud compute instances create reddit-app \
  --zone=europe-north1-a \
  --machine-type=g1-small \
  --tags=puma-server \
  --image-family=reddit-full \
  --image-project=$GCP_PROJECT_ID \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-standard
