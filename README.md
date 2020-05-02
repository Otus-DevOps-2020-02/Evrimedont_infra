# Evrimedont_infra

Евгений Баранов OTUS-DevOps-2020-02

- [1. Домашнее задание №2: ChatOps](#1.-Домашнее-задание-№2-ChatOps)
- [2. Домашнее задание №3](#2.-Домашнее-задание-№3)

## 1. Домашнее задание №2 ChatOps
- добавлен шаблон для pull request-а PULL_REQUEST_TEMPLATE.md
- добавлена проверка на завершающий перенос строки и отсутствие завершающих пробелов через утилиту  pre-commit
- настроена интеграция между Slack и репозиторием на GitHub
- настроена интеграция с Travis CI для проверки заданий

## 2. Домашнее задание №3
~~~
bastion_IP: 35.217.26.71
someinternalhost_IP: 10.166.0.3
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
- на локальной машине конфигурационый файл настроенго VPN сервера был загружен в клиент OpenVPN и проверено подключение к VPN серверу:
    ```bash
    evgeniy@ehome:~$ ssh -i ~/.ssh/gcp_otus_appuser appuser@10.166.0.3 hostname
    someinternalhost
    ```
