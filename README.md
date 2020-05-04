# Evrimedont_infra

Евгений Баранов OTUS-DevOps-2020-02

- [1. Домашнее задание №2: ChatOps](#1.-Домашнее-задание-№2-ChatOps)
- [2. Домашнее задание №3: CloudBastion](#2.-Домашнее-задание-№3-CloudBastion)
- [3. Домашнее задание №4: CloudTestApp](#2.-Домашнее-задание-№4-CloudTestApp)

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
