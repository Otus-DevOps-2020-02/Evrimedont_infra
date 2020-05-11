# Evrimedont_infra

Евгений Баранов OTUS-DevOps-2020-02

- [1. Домашнее задание №2: ChatOps](#1.-Домашнее-задание-№2-ChatOps)
- [2. Домашнее задание №3: CloudBastion](#2.-Домашнее-задание-№3-CloudBastion)
- [3. Домашнее задание №4: CloudTestApp](#3.-Домашнее-задание-№4-CloudTestApp)
- [4. Домашнее задание №5: PackerBase](#4.-Домашнее-задание-№5-PackerBase)
  - [4.1 Самостоятельная работа](#4.1.-Самостоятельная-работа)
  - [4.2 Задание со *](#4.2.-Задание-со-*)
- [5. Домашнее задание №6: Terraform-1](#5.-Домашнее-задание-№6-Terraform-1)
  - [5.1 Самостоятельная работа](#5.1.-Самостоятельная-работа)
  - [5.2 Задание со *](#5.2.-Задание-со-*)

## 1. Домашнее задание №2 ChatOps
- добавлен шаблон для pull request-а PULL_REQUEST_TEMPLATE.md
- добавлена проверка на завершающий перенос строки и отсутствие завершающих пробелов через утилиту  pre-commit
- настроена интеграция между Slack и репозиторием на GitHub
- настроена интеграция с Travis CI для проверки заданий

## 2. Домашнее задание №3 CloudBastion
~~~
bastion_IP = 35.217.26.71
someinternalhost_IP = 10.166.0.3
~~~
### 2.1. Знакомство с Google Cloud Platform
- создана учётная запись в GCP
- создан новый проект Infra
- на локальной машине утилитой **ssh-keygen** создана пара из приватного и публичного ssh ключей для пользователя user:
```bash
ssh-keygen -t rsa -f ~/.ssh/gcp_otus_appuser -C appuser -P ""
```
- сгенерированный публичный ключ ~/.ssh/gcp_otus_appuser.pub добавлен в раздел GCP Compute Engine \ Metadata \ SSH Keys
- в разделе GCP Compute Engine \ VM instances созданы две виртуальные машины:
  - **bastion** со статическим внешним IP
  - **someinternalhost** без внешнего статического IP

### 2.2. Подключение к GCP через Bastion Host
- выполнено подключение к виртуалке только с внутренним IP TCP forwarding ssh-соединения используя SSH Agent Forwarding:
```bash
    evgeniy@ehome:~$ ssh -A appuser@35.217.26.71
    appuser@bastion:~$ ssh appuser@10.166.0.3
```
- исследована возможность подключения к someinternalhost одной командой:
  - вариант 1: используя Local TCP forwarding ssh-соединения:
    ```bash
    # подключаемся к bastion и начинаем слушать локальный порт 2222
    evgeniy@ehome:~$ ssh -L 2222:10.166.0.3:22 appuser@35.217.26.71
    # подключаясь к локальному порту 2222 попадаем на нужную нам виртуальную машину
    evgeniy@ehome:~$ ssh -p 2222 appuser@localhost hostname
    someinternalhost
    ```
  - вариант 2: используя Jump Host:
    ```bash
    evgeniy@ehome:~$ ssh -J appuser@35.217.26.71 appuser@10.166.0.3 hostname
    someinternalhost
    ```
  - вариант 3: используя ProxyCommand:
    ```bash
    evgeniy@ehome:~$ ssh -o ProxyCommand="ssh -W %h:%p appuser@35.217.26.71" appuser@10.166.0.3 hostname
    someinternalhost
    ```
- сделана возможность подключение к машине someinternalhost по алиасу командой **ssh someinternalhost**:
  - за основу взят вариант с Jump Host. Внесены правки в локальный файл ~/.ssh/config:
    ```bash
    Host bastion
            Hostname 35.217.26.71
            User appuser
            PasswordAuthentication no
    Host someinternalhost
            Hostname 10.166.0.3
            User appuser
            PasswordAuthentication no
            ProxyJump bastion
    ```
  - подключиться к удалённой машине теперь можно так:
    ```bash
    evgeniy@ehome:~$ ssh someinternalhost hostname
    someinternalhost
    ```

### 2.3. Подключение через VPN-сервер
- по инструкции к уроку был создан Pritunl VPN-сервер для серверов GCP, выполнена конфигурация этого сервера
- на локальной машине конфигурационный файл настроенного VPN сервера был загружен в клиент OpenVPN и проверено подключение к VPN серверу:
    ```bash
    evgeniy@ehome:~$ ssh -i ~/.ssh/gcp_otus_appuser appuser@10.166.0.3 hostname
    someinternalhost
    ```
- на виртуальной машине bastion был установлен Certbot:
    ```bash
    sudo apt-get update
    sudo apt-get install software-properties-common
    sudo add-apt-repository universe
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get install certbot
    sudo certbot certonly --standalone
    ```
- в настройках веб панели Pritunl в разделе Setting поле **Lets Encrypt Domain** было настроено как **35.217.26.71.xip.io**. Веб интерфейс Pritunl теперь доступен по домену **https://35.217.26.71.xip.io/**  и имеет валидный сертификат от Let’s Encrypt.

## 3. Домашнее задание №4 CloudTestApp
~~~
testapp_IP = 35.228.134.129
testapp_port = 9292
~~~
- на локальной машине был установлен Google Cloud SDK, проведена инициализация gcloud:
    ```bash
    evgeniy@ehome:~$ gcloud auth list
       Credentialed Accounts
    ACTIVE  ACCOUNT
    *       evrimedont@gmail.com

    To set the active account, run:
        $ gcloud config set account `ACCOUNT`
    ```
- утилитой gcloud создан новый инстанс reddit-app:
    ```bash
    evgeniy@ehome:~$ gcloud compute instances create reddit-app \
    --boot-disk-size=10GB \
    --image-family ubuntu-1604-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=g1-small \
    --tags puma-server \
    --restart-on-failure
    WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
    Created [https://www.googleapis.com/compute/v1/projects/infra-275915/zones/europe-north1-a/instances/reddit-app].
    NAME        ZONE             MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
    reddit-app  europe-north1-a  g1-small                   10.166.0.5   35.228.134.129  RUNNING
    ```
- на созданной виртуальной машине по инструкции были установлены ruby и mongodb, скопирован код тестового приложения и сделан его деплой;
- через веб интерфейс GCP было добавлено правило в фаерволе default-puma-server на tcp порт 9292;
- вышеиспользованные команды были сгруппированы в bash файлы install_ruby.sh, install_mongodb.sh, deploy.sh. Файлам были даны права на исполнение командой chmod +x;
- подготовлен скрипт startup_script.sh, который устанавливает ruby и bundler, mongodb, получвет, инициализрует и деплоем тестовое приложение.
- изучен вопрос создания виртуальной машины через gcloud с созданным заранее startup_script.sh:
    ```bash
    $ gcloud compute instances delete reddit-app
    ...
    Deleted [https://www.googleapis.com/compute/v1/projects/infra-275915/zones/europe-north1-a/instances/reddit-app].
    $ gcloud compute instances create reddit-app \
      --boot-disk-size=10GB \
      --image-family ubuntu-1604-lts \
      --image-project=ubuntu-os-cloud \
      --machine-type=g1-small \
      --tags puma-server \
      --restart-on-failure \
      --metadata-from-file startup-script=./startup_script.sh
    WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
    Created [https://www.googleapis.com/compute/v1/projects/infra-275915/zones/europe-north1-a/instances/reddit-app].
    NAME        ZONE             MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
    reddit-app  europe-north1-a  g1-small                   10.166.0.6   35.228.134.129  RUNNING
    ```
- сделана возможность подзагрузки startup скрипта при создании виртуальной машине методом **gcloud compute instances create** через параметр startup-script-url. Для этого предварительно скрипт был помещён в Google Storage.
    ```bash
    $ gsutil mb -l europe-north1 gs://evrimedont-otus
    Creating gs://evrimedont-otus/...
    $ gsutil cp startup_script.sh gs://evrimedont-otus/devops/cloud-testapp/startup_script.sh
    Copying file://startup_script.sh [Content-Type=text/x-sh]...
    / [1 files][  536.0 B/  536.0 B]
    Operation completed over 1 objects/536.0 B.
    $ gcloud compute instances delete reddit-app
    ...
    Deleted [https://www.googleapis.com/compute/v1/projects/infra-275915/zones/europe-north1-a/instances/reddit-app].
    $ gcloud compute instances create reddit-app \
        --boot-disk-size=10GB \
        --image-family ubuntu-1604-lts \
        --image-project=ubuntu-os-cloud \
        --machine-type=g1-small \
        --tags puma-server \
        --restart-on-failure \
        --metadata startup-script-url=gs://evrimedont-otus/devops/cloud-testapp/startup_script.sh
    WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
    Created [https://www.googleapis.com/compute/v1/projects/infra-275915/zones/europe-north1-a/instances/reddit-app].
    NAME        ZONE             MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
    reddit-app  europe-north1-a  g1-small                   10.166.0.6   35.228.134.129  RUNNING
    ```
- через веб интерфейс GCP был удалён Firewall rule "default-puma-server" и после этого создан то же правило через gcloud:
    ```bash
    gcloud compute firewall-rules create default-puma-server \
      --allow tcp:9292 \
      --target-tags=puma-server
    ```

## 4. Домашнее задание №5 PackerBase

### 4.1. Самостоятельная работа

- с официального сайта packer.io был скачен архив с бинарником packer. Файл packer был перемещён в ~/bin, данная директория была добавлена в переменную PATH.
    ```bash
    $ packer -v
    1.5.6
    ```
- создан Application Default Credentials (ADC) для управления ресурсами GCP через Packer
    ```bash
    $ gcloud auth application-default login --no-launch-browser
    ...
    Credentials saved to file: [/home/evrimedont/.config/gcloud/application_default_credentials.json]

    These credentials will be used by any library that requests Application Default Credentials (ADC).
    ```
- скрипты установки ruby и mongodb немного откорректированы (добавлена команда **set -e** в начале скриптов, команда **apt** заменена на команду **apt-get**) и скопированы в директорию packer/scripts.
- в директории packer создан шаблон Packer ubuntu16.json:
    ```json
    {
      "builders": [
        {
          "type": "googlecompute",
          "project_id": "infra-275915",
          "image_name": "reddit-base-{{timestamp}}",
          "image_family": "reddit-base",
          "source_image_family": "ubuntu-1604-lts",
          "zone": "europe-north1-a",
          "ssh_username": "appuser",
          "machine_type": "f1-micro"
        }
      ],
      "provisioners": [
        {
          "type": "shell",
          "script": "scripts/install_ruby.sh",
          "execute_command": "sudo {{.Path}}"
        },
        {
          "type": "shell",
          "script": "scripts/install_mongodb.sh",
          "execute_command": "sudo {{.Path}}"
        }
      ]
    }
    ```
- получившийся шаблон был проверен командой **packer validate**:
    ```bash
    $ packer validate ubuntu16.json
    Template validated successfully.
    ```
- после успешной проверки была запущена сборка образа:
    ```bash
    $ packer build ubuntu16.json
    ...
    ==> Builds finished. The artifacts of successful builds are:
    --> googlecompute: A disk image was created: reddit-base-1588718564
    ```
- через web интерфейс GCP Compute Engine был создан инстанс reddit-app (предварительно удалён предыдущий) на базе полученного образа, через теги работы с сетью добавлен тег **puma-server**;
- через ssh было произведено подключение к созданной VM и вручную выполнены команды скачивания и деплоя тестового приложения reddit, приложение доступно по адресу **http://35.228.202.64:9292/**;
- был доработан файл шаблона **ubuntu16.json**. Был создан файл **variables.json** с настраиваемыми переменными шаблона, файл добавлен в .gitignore. В систему контроля версий был добавлен файл **variables.json.example**. Также была доработана секция **builders** packer шаблона:
    ```json
    {
      "variables": {
        "project_id": "",
        "machine_type": "f1-micro",
        "zone": "europe-north1-a",
        "source_image_family": "",
        "disk_size": "10",
        "disk_type": "pd-standard",
        "network": "default",
        "ssh_username": "appuser"
      },
      "builders": [
        {
          "type": "googlecompute",
          "project_id": "{{user `project_id`}}",
          "machine_type": "{{user `machine_type`}}",
          "zone": "{{user `zone`}}",
          "image_name": "reddit-base-{{isotime \"20060102150405\"}}",
          "image_family": "reddit-base",
          "image_description": "Template image for test reddit application. It contains ruby and mongodb installations.",
          "source_image_family": "{{user `source_image_family`}}",
          "ssh_username": "{{user `ssh_username`}}",
          "disk_size": "{{user `disk_size`}}",
          "disk_type": "{{user `disk_type`}}",
          "network": "{{user `network`}}",
          "tags": "puma-server,test"
        }
      ],
      "provisioners": [
        {
          "type": "shell",
          "script": "scripts/install_ruby.sh",
          "execute_command": "sudo {{.Path}}"
        },
        {
          "type": "shell",
          "script": "scripts/install_mongodb.sh",
          "execute_command": "sudo {{.Path}}"
        }
      ]
    }
    ```
- дальше снова был удалён инстанс reddit-app и через утилиту gcloud развёрнут снова командой:
    ```bash
    gcloud compute instances create reddit-app \
      --zone=europe-north1-a \
      --machine-type=g1-small \
      --tags=puma-server \
      --image=reddit-base-20200508223001 \
      --image-project=infra-275915 \
      --boot-disk-size=15GB \
      --boot-disk-type=pd-standard
    ```
- в ручном режиме на полученной виртуальной машине был добавлен код проекта и запущен веб сервер puma. Приложение снова доступно по адресу **http://35.228.202.64:9292/**.

### 4.2. Задание со *

- был создан новый шаблон для packer **immutable.json**, который в качестве source_image_family берёт созданный ранее образ **reddit-base**;
- был откорректирован файл деплоя scripts/deploy.sh, запуск веб сервера **puma** был переделан на использование systemd unit;
- был сделан скрипт **create-reddit-vm.sh** для автоматического запуска packer build и вслед за ним создания виртуальной машины через gcloud;

## 5. Домашнее задание №6 Terraform 1

### 5.1. Самостоятельная работа

- были удалены ключи пользователя appuser в интерфейсе GCP Metadata \ Metadata \ SSH Keys
- на локальную систему был установлен terraform по официальной документации;
- была создана директория **terraform**, в ней файл **main.tf** с блоками terraform и provider. Также в файл .gitignore проекта добавлены служебные файлы terraform;
- через веб интерфейс GCP был создан новый Service Accounts для работы с terraform и создан ключ для него. Ключ был сохранён на локальной машине и прописан путь до него в переменную окружения GOOGLE_CLOUD_KEYFILE_JSON;
- выполнена команда terraform init;
- в файл **main.tf** был добавлен блок resource "google_compute_instance" "app";
- были выполнены команды **terraform plan** и **terraform apply**;
- в resource "google_compute_instance" "app" добавлен раздел "metadata" с публичным ключом к данной рабочей виртуалки;
- был создан файл **outputs.tf** для просмотра выходных переменных;
- в файл конфига **main.tf** был добавлен resource "google_compute_firewall" "firewall_puma" с описанием правила фаервола для приложения, а в ресурс "google_compute_instance" "app" добавлен тег **reddit-app**;
- в файл конфига **main.tf** были добавлены provisioner-ы "file" и " "remote-exec", они клонируют приложение reddit, настраивают sysated unit для запуска службы puna.service;
- были созданы файлы **variables.tf** и **terraform.tfvars** и параметризованы все необходимые переменные;
- была выполнена команда **terraform destroy**, затем **terraform apply**. Результат работы приложения можно увидеть по адресу http://35.228.103.163:9292/.
- во input переменные был добавлен путь до приватного ключа и зона со значением по умолчанию **europe-north1-a**;
- командой **terraform fmt** были отфорамтированы конфигурационные файлы Terraform;
- был добавлен файл **terraform.tfvars.example** с тестовыми значениями для сохранения в систему контроля версий;

### 5.2. Задание со *

- используя ресурс **google_compute_project_metadata_item** в шаблон **main.tf** были добавлены два ssh ключа для пользователей appuser1 и appuser2 на уровне всего проекта:
    ```hcl-terraform
    resource "google_compute_project_metadata_item" "default" {
      key   = "ssh-keys"
      value = <<SSH_KEYS
        appuser1:${file(var.public_key_path)}
        appuser2:${file(var.public_key_path)}
      SSH_KEYS
    }
    ```
- в ходе эксперимента выяснилось, что при добавлении ssh ключей через web интерфейс GCP, а потом запуска команды **terraform apply** созданные через веб интерфейс ключи удаляются.
