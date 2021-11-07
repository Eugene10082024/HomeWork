## Развертывание кластера Postgresql + Patroni на Astra Linux SE 1.6 

Состав кластера: 

   astra-patroni01 - 192.168.122.103 
   
   astra-patroni02 - 192.168.122.104
   
   astra-patroni03 - 192.168.122.105 

Схема кластера:



### 1. Настройка пакета postgres

Выполняем на всех серверах кластера patroni.

#### 1.1. Устанавливаем пакет posgres из repo astra:

        apt-get install postgresql-astra postgresql-contrib
           
#### 1.2. Отключение мандатного контроля для ненайденных юзеров(replicator/postgres)

        mcedit /etc/parsec/mswitch.conf
        zero_if_notfound: yes

#### 1.3. Остановка и отключение сервиса postgresql.

        systemctl disable postgresql
        systemctl stop postgresql
        
#### 1.4. Удаление созданного кластера postgres.

После развертывания postgres в astra linux создается кластер по умолчанию.

Местонахождение - /var/lib/postgresql/9.6/main

Удаляем все из каталога /var/lib/postgresql/9.6/main/ 

         rm -rf /var/lib/postgresql/9.6/main/*
  
### 2. Установка и первоначальная настройка кластера etcd. 
Выполняется на всех серверах, где будет развернут кластер etcd.

В данном примере кластер etcd будет развернут на astra-patroni01, astra-patroni02, astra-patroni03

#### 2.1. Скачаем bin архив etcd на каждый сервер кластера etcd.  
Различные версии etcd находится по адресу: https://github.com/etcd-io/etcd/releases/
Для установки и настройки используем - etcd-v3.5.1-linux-amd64
   
#### 2.2. Разваричиваем разварачиваем скаченный архив:
Для развертывания создаем папку и разархивируем скопированный архив.

     mkdir /home/asarafanov/install 
     cd /home/asarafanov/install 
     tar xzvf etcd-v3.5.1-linux-amd64
     rm etcd-v3.5.1-linux-amd64
   
#### 2.3. Копируем bin файлы etcd в папку /usr/local/bin/

     cp /home/asarafanov/install/etcd-v3.5.1-linux-amd64/etcd* /usr/local/bin/
     можно и так:
     mv /home/asarafanov/install/etcd-v3.5.1-linux-amd64/etcd* /usr/local/bin/
   
#### 2.4.Проверяем правильность развернутой версии.

     etcd --version
    
#### 2.5.Создаем пользователя под которым будет работать etcd и необходимые каталоги с соответсвующим владельцем и правами.

     groupadd --system etcd
     useradd -s /sbin/nologin --system -g etcd etcd
     mkdir -p /var/lib/etcd/
     chown -R etcd:etcd /var/lib/etcd/
     
#### 2.6 Настраиваем фаервол.(Если он включен): 
    
    ufw allow proto tcp from any to any port 2379,2380

    
#### 2.7. Настраиваем логирование. 

Открываем файл для редактирования mcedit /etc/rsyslog.d/etcd.conf и добавляем строки:

        if $programname == 'etcd' then /var/log/etcd/etcd.log

        & stop

    
#### 2.8. Настройваем ротацию в rsyslog и рестартуем сервис rsyslog.

        mcedit /etc/rsyslog.conf
        $FileCreateMode 0644
        
        systemctl restart rsyslog     
     

   
### 3. Настройка кластера etcd. 

#### 3.1. Создаем лидера кластера etcd (в качестве примера берем - astra-patroni01 - 192.168.122.103). 

Все действия выполняем под пользоватем root или из под sudo

##### 3.1.1. Создание переменных в терминале.

Для автоматического создания скрипта запуска etcd сервиса на ноде (astra-patroni01 - 192.168.122.103) созданим переменные.

    INT_NAME="eth0"

    ETCD_HOST_IP=$(ip addr show $INT_NAME | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    ETCD_NAME=$(hostname -s)
    
##### 3.1.2. Создание unit запуска etcd.service на astra-patroni01 - 192.168.122.103 

Копируем то что ниже и вктавляем в терминал. После чего нажимаем Enter и создаем unit файл: /etc/systemd/system/etcd.service

Файл приведенный ниже размещен по адресу: [unit etcd.service для astra-patroni01 ](https://github.com/Aleksey-10081967/HomeWork/blob/main/HW-lesson-40-a/files/etcd01.service)

ВНИМАНИЕ -  При первом запуске etcd.service будет создан кластер с именем cluster-etcd. Для создания кластера с другим именем необходимо его поменять в строке:     --initial-cluster-token <cluster-etcd> 
             
        cat <<EOF | sudo tee /etc/systemd/system/etcd.service
        [Unit]
        Description=etcd service
        [Service]
        Type=notify
        User=etcd
        ExecStart=/usr/local/bin/etcd \\
        --name ${ETCD_NAME} \\
        --data-dir=/var/lib/etcd \\
        --enable-v2=true \\
        --initial-advertise-peer-urls http://${ETCD_HOST_IP}:2380 \\
        --listen-peer-urls http://${ETCD_HOST_IP}:2380 \\
        --listen-client-urls http://${ETCD_HOST_IP}:2379,http://127.0.0.1:2379 \\
        --advertise-client-urls http://${ETCD_HOST_IP}:2379 \\
        --initial-cluster-token <cluster-etcd> \\
        --initial-cluster ${ETCD_NAME}=http://${ETCD_HOST_IP}:2380 \\
        --initial-cluster-state new \
       
        [Install]
        WantedBy=multi-user.target
        EOF

После выполнения команды можно проверить что получилось выполнив команду;
    
    less /etc/systemd/system/etcd.service

##### 3.1.3. Запуск etcd.service на ноде astra-patroni01 - 192.168.122.103.

    systemctl daemon-reload
    systemctl enable etcd
    systemctl start etcd
   
##### 3.1.4. Проверка работы созданого кластера etcd.
Проверка выполняется как в api версии 2, так и версии  3, 

    ETCDCTL_API=3 etcdctl member list

    Вывод команды примерно такой:
    e8080638f53e747c, started, astra-patroni01, http://192.168.122.103:2380, http://192.168.122.103:2379, false
    
    ETCDCTL_API=2 etcdctl member list

    Вывод команды примерно такой:
    e8080638f53e747c: name=astra-patroni01 peerURLs=http://192.168.122.103:2380 clientURLs=http://192.168.122.103:2379 isLeader=true
    
    ETCDCTL_API=3 etcdctl endpoint status --cluster -w table
    Вывод команды примерно такой:
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | http://192.168.122.103:2379 | e8080638f53e747c |   3.5.1 |   20 kB |      true |      false |         2 |          4 |                  4 |        |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+


#### 3.2. Добавлнение второго сервера в кластер etcd - astra-patroni02 - 192.168.122.104.

##### 3.2.1. Добавление второго сервера astra-patroni02 - 192.168.122.104 в список кластера.
Данная операция выполняется на первом сервере astra-patroni01 - 192.168.122.103.

    etcdctl member add astra-patroni02 --peer-urls=http://192.168.122.104:2380
   
    Вывод команды:
    Member 232542f9074f4c33 added to cluster ad3b449a63a41087
    ETCD_NAME="astra-patroni02"
    ETCD_INITIAL_CLUSTER="astra-patroni02=http://192.168.122.104:2380,astra-patroni01=http://192.168.122.103:2380"
    ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.104:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"

    
##### 3.2.2 Создание unit etcd.service на второй ноде. Выполняется на второй ноде (astra-patroni02 - 192.168.122.104)

Для автоматического создания скрипта запуска etcd сервиса на ноде (astra-patroni02 - 192.168.122.104) созданим переменные.

    INT_NAME="eth0"

    ETCD_HOST_IP=$(ip addr show $INT_NAME | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    ETCD_NAME=$(hostname -s)

    
Перед копированием скрипта создания etc.service необходимо внести изменения в следующие параметры скрипта:
    --initial-cluster-token <имя кластера>  - в данной строке должен быть указано имя кластера которое было определено при инициализаии перовй ноды.
    В примере используется имя кластера: cluster-etcd: --initial-cluster-token <cluster-etcd>

    --initial-cluster astra-patroni02=http://192.168.122.104:2380,astra-patroni01=http://192.168.122.103:2380 \\

Значение данного параметра можно взять скопировав значение переменной ETCD_INITIAL_CLUSTER полученной на шаге 3.2.1:
    --initial-cluster astra-patroni02=http://192.168.122.104:2380,astra-patroni01=http://192.168.122.103:2380 \\

    или самостоятельно заполнить шаблон данного параметра.
    --initial-cluster <node01-hostname>=http://<node01-IP>:2380,<node02-hostname>=http://<node02-IP>2380 


Копируем то что ниже и вcтавляем в терминал. После чего нажимаем Enter и создаем unit файл: /etc/systemd/system/etcd.service

cat <<EOF | sudo tee /etc/systemd/system/etcd.service

[Unit]

Description=etcd service

[Service]

Type=notify

User=etcd

ExecStart=/usr/local/bin/etcd \\

--name ${ETCD_NAME} \\

--data-dir=/var/lib/etcd \\

--enable-v2=true \\

--listen-peer-urls http://0.0.0.0:2380 \\

--listen-client-urls http://0.0.0.0:2379 \\

--initial-advertise-peer-urls http://${ETCD_HOST_IP}:2380 \\

--advertise-client-urls http://${ETCD_HOST_IP}:2379 \\

--initial-cluster-token <cluster-etcd> \\

--initial-cluster astra-patroni02=http://192.168.122.104:2380,astra-patroni01=http://192.168.122.103:2380 \\

--initial-cluster-state existing \

[Install]

WantedBy=multi-user.target

EOF

После выполнения команды можно проверить что получилось выполнив команду;
    
    less /etc/systemd/system/etcd.service

##### 3.2.3. Запуск etcd.service на второй ноде astra-patroni02 - 192.168.122.104.

    systemctl daemon-reload
    systemctl enable etcd

    systemctl start etcd
   
##### 3.2.5. Проверка работы нод кластера. Команды данного пункта выполняем на первой ноде (astra-patroni01 - 192.168.122.103)
Проверка выполняется как в api версии 2, так и версии  3, 

    root@astra-patroni01:/var/lib/etcd# ETCDCTL_API=3 etcdctl member list
    232542f9074f4c33, started, astra-patroni02, http://192.168.122.104:2380, http://192.168.122.104:2379, false
    e8080638f53e747c, started, astra-patroni01, http://192.168.122.103:2380, http://192.168.122.103:2379, false
    
    root@astra-patroni01:/var/lib/etcd#  ETCDCTL_API=2 etcdctl member list
    232542f9074f4c33: name=astra-patroni02 peerURLs=http://192.168.122.104:2380 clientURLs=http://192.168.122.104:2379 isLeader=false
    e8080638f53e747c: name=astra-patroni01 peerURLs=http://192.168.122.103:2380 clientURLs=http://192.168.122.103:2379 isLeader=true
    
    root@astra-patroni01:/var/lib/etcd# ETCDCTL_API=3 etcdctl endpoint status --cluster -w table
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | http://192.168.122.104:2379 | 232542f9074f4c33 |   3.5.1 |   20 kB |     false |      false |         3 |          7 |                  7 |        |
    | http://192.168.122.103:2379 | e8080638f53e747c |   3.5.1 |   20 kB |      true |      false |         3 |          7 |                  7 |        |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    root@astra-patroni01:/var/lib/etcd# 

Из вывода команд видно что вторая нода добавлена в кастер и первая нода является лидером кластера.


#### 3.3. Добавлнение третий ноды (astra-patroni03 - 192.168.122.105) в кластер etcd.

##### 3.3.1. Добавление третьей ноды (astra-patroni03 - 192.168.122.105) в кластер.
Данная операция выполняется на первой ноде ((astra-patroni01 - 192.168.122.103).

    etcdctl member add astra-patroni03 --peer-urls=http://192.168.122.105:2380
    
    Вывод команды:
    root@astra-patroni01:/var/lib/etcd#     etcdctl member add astra-patroni03 --peer-urls=http://192.168.122.105:2380
    Member 6580a3065447af4e added to cluster ad3b449a63a41087
    ETCD_NAME="astra-patroni03"
    ETCD_INITIAL_CLUSTER="astra-patroni02=http://192.168.122.104:2380,astra-patroni03=http://192.168.122.105:2380,astra-patroni01=http://192.168.122.103:2380"
    ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.105:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"

##### 3.3.2 Создание unit etcd.service на третьей ноде. Выполняется на третьей ноде (astra-patroni03 - 192.168.122.105)

Для автоматического создания скрипта запуска etcd сервиса на ноде (astra-patroni03 - 192.168.122.105) созданим переменные.

    INT_NAME="eth0"

    ETCD_HOST_IP=$(ip addr show $INT_NAME | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    ETCD_NAME=$(hostname -s)

    
Перед копированием скрипта создания etc.service необходимо внести изменения в следующие параметры скрипта:
    --initial-cluster-token <имя кластера>  - в данной строке должен быть указано имя кластера которое было определено при инициализаии перовй ноды.
    В примере используется имя кластера: cluster-etcd: --initial-cluster-token <cluster-etcd>

    --initial-cluster <строка>

Значение данного параметра можно взять скопировав значение переменной ETCD_INITIAL_CLUSTER полученной на шаге 3.3.1:
    --initial-cluster astra-patroni02=http://192.168.122.104:2380,astra-patroni03=http://192.168.122.105:2380,astra-patroni01=http://192.168.122.103:2380 \\

или самостоятельно заполнить шаблон данного параметра.
    --initial-cluster <node01-hostname>=http://<node01-IP>:2380,<node02-hostname>=http://<node02-IP>2380,<node03-hostname>=http://<node03-IP>2380 


Копируем подготовленный скрипт и вставляем в терминал. После чего нажимаем Enter и создаем unit файл: /etc/systemd/system/etcd.service


cat <<EOF | sudo tee /etc/systemd/system/etcd.service

[Unit]

Description=etcd service

[Service]

Type=notify

User=etcd

ExecStart=/usr/local/bin/etcd \\

--name ${ETCD_NAME} \\

--data-dir=/var/lib/etcd \\

--enable-v2=true \\

--listen-peer-urls http://0.0.0.0:2380 \\

--listen-client-urls http://0.0.0.0:2379 \\

--initial-advertise-peer-urls http://${ETCD_HOST_IP}:2380 \\

--advertise-client-urls http://${ETCD_HOST_IP}:2379 \\

--initial-cluster-token <cluster-etcd> \\

--initial-cluster astra-patroni02=http://192.168.122.104:2380,astra-patroni03=http://192.168.122.105:2380,astra-patroni01=http://192.168.122.103:2380 \\

--initial-cluster-state existing \

[Install]

WantedBy=multi-user.target

EOF

После выполнения команды можно проверить что получилось выполнив команду;
    
    less /etc/systemd/system/etcd.service

##### 3.3.3. Запуск etcd.service на второй ноде astra-patroni03 - 192.168.122.105.

    systemctl daemon-reload
    systemctl enable etcd

    systemctl start etcd
   
##### 3.2.5. Проверка работы нод кластера. Команды данного пункта выполняем на первой ноде (astra-patroni01 - 192.168.122.103)
Проверка выполняется как в api версии 2, так и версии  3, 

    root@astra-patroni01:/var/lib/etcd# ETCDCTL_API=3 etcdctl member list
    232542f9074f4c33, started, astra-patroni02, http://192.168.122.104:2380, http://192.168.122.104:2379, false
    6580a3065447af4e, started, astra-patroni03, http://192.168.122.105:2380, http://192.168.122.105:2379, false
    e8080638f53e747c, started, astra-patroni01, http://192.168.122.103:2380, http://192.168.122.103:2379, false
    
    root@astra-patroni01:/var/lib/etcd#  ETCDCTL_API=2 etcdctl member list
    232542f9074f4c33: name=astra-patroni02 peerURLs=http://192.168.122.104:2380 clientURLs=http://192.168.122.104:2379 isLeader=false
    6580a3065447af4e: name=astra-patroni03 peerURLs=http://192.168.122.105:2380 clientURLs=http://192.168.122.105:2379 isLeader=false
    e8080638f53e747c: name=astra-patroni01 peerURLs=http://192.168.122.103:2380 clientURLs=http://192.168.122.103:2379 isLeader=true
    
    root@astra-patroni01:/var/lib/etcd# ETCDCTL_API=3 etcdctl endpoint status --cluster -w table
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | http://192.168.122.104:2379 | 232542f9074f4c33 |   3.5.1 |   20 kB |     false |      false |         3 |          9 |                  9 |        |
    | http://192.168.122.105:2379 | 6580a3065447af4e |   3.5.1 |   20 kB |     false |      false |         3 |          9 |                  9 |        |
    | http://192.168.122.103:2379 | e8080638f53e747c |   3.5.1 |   20 kB |      true |      false |         3 |          9 |                  9 |        |
    +-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+


Кластер etcd из трех поднят.


#### 3.4. Создание пользователя root в etcd и включение авторизации по пользователю.
Все действия выполняются на первой ноде кластера.

#### 3.4.1. Создание пользователя root
    root@astra-patroni01:/var/lib/etcd# etcdctl user add root
    Password of root: 
    Type password of root again for confirmation: 
    User root created
    root@astra-patroni01:/var/lib/etcd# etcdctl user get root
    User: root
    Roles:

#### 3.4.2. Включение авторизации по учетной записи    
    root@astra-patroni01:/var/lib/etcd# etcdctl auth enable
    {"level":"warn","ts":"2021-10-24T10:48:19.666+0300","logger":"etcd-client","caller":"v3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00031ca80/127.0.0.1:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: root user does not have root role"}
    Authentication Enabled

#### 3.4.3. Проверка работы включенной авторизации    

Без указания учетной записи - ошибка.
        root@astra-patroni01:/var/lib/etcd# etcdctl user get root
        {"level":"warn","ts":"2021-10-24T10:49:07.783+0300","logger":"etcd-client","caller":"v3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000432380/127.0.0.1:2379","attempt":0,"error":"rpc error: code = InvalidArgument desc = etcdserver: user name is empty"}
        Error: etcdserver: user name is empty
        
С указанием учетной записи - все норм.        
    root@astra-patroni01:/var/lib/etcd# etcdctl --user root user get root
    Password: 
    User: root
    Roles: root
    root@astra-patroni01:/var/lib/etcd# 

Настройка кластера etcd завершена.


### 4. Установка Pаtroni.

#### 4.1. Установка дополнительных пакетов (выполняем на всех нодах кластера).
##### 4.1.1. Установка python3.5.

            apt -y install python3.5

            Проверка версии:  python3 --version

            
##### 4.1.2. Установка python3-pip. 

            apt -y install gcc 
            apt -y install python3.5-dev
            apt -y install python3-psycopg2
            apt -y install python3-pip
            
Если вдруг будет не стыковка с версиями пакетами можно попробовать -   aptitude install           
 

#### 4.2. Загрузка доп пакетов patroni c хоста имеющего доступ в Интернет.
Перед тем как скачать необходимые пакеты необходимо на данный хост установить пакеты п. 4.1.1 - 4.1.2

Выполняем следующие команды 
    root@astra-control: mkdir install-patroni[etcd]
    root@astra-control:cd /home/asarafanov/install-patroni[etcd]
    root@astra-control:/home/asarafanov/install# python3 -m pip download patroni[etcd]
    root@astra-control:/home/asarafanov/install-psycopg2-binary# python3 -m pip download psycopg2-binary

Имеем:     
    root@astra-control:/home/asarafanov/install-patroni[etcd]# ls -al
    итого 2516
    drwxr-xr-x  2 root       root         4096 окт 24 12:46 .
    drwxr-x--- 20 asarafanov asarafanov   4096 окт 24 13:21 ..
    -rw-r--r--  1 root       root        82780 окт 24 12:46 click-7.1.2-py2.py3-none-any.whl
    -rw-r--r--  1 root       root       188353 окт 24 12:46 dnspython-1.16.0-py2.py3-none-any.whl
    -rw-r--r--  1 root       root       219752 окт 24 12:46 patroni-2.1.1-py3-none-any.whl
    -rw-r--r--  1 root       root        22394 окт 24 12:46 prettytable-1.0.1-py2.py3-none-any.whl
    -rw-r--r--  1 root       root       470886 окт 24 12:46 psutil-5.8.0.tar.gz
    -rw-r--r--  1 root       root       247702 окт 24 12:46 python_dateutil-2.8.2-py2.py3-none-any.whl
    -rw-r--r--  1 root       root       2951610 окт 24 13:21 psycopg2_binary-2.8.6-cp35-cp35m-manylinux1_x86_64.whl
    -rw-r--r--  1 root       root        37270 окт 24 12:46 python-etcd-0.4.5.tar.gz
    -rw-r--r--  1 root       root       269377 окт 24 12:46 PyYAML-5.3.1.tar.gz
    -rw-r--r--  1 root       root       785194 окт 24 12:46 setuptools-50.3.2-py3-none-any.whl
    -rw-r--r--  1 root       root        11053 окт 24 12:46 six-1.16.0-py2.py3-none-any.whl
    -rw-r--r--  1 root       root       138764 окт 24 12:46 urllib3-1.26.7-py2.py3-none-any.whl
    -rw-r--r--  1 root       root        30763 окт 24 12:46 wcwidth-0.2.5-py2.py3-none-any.whl
    -rw-r--r--  1 root       root        42808 окт 24 12:46 ydiff-1.2.tar.gz

После чего переносим скачинные файлы на ноды кластера patroni.
    /home/asarafanov/install-patroni[etcd]# scp * asarafanov@192.168.122.105:/home/asarafanov/install/python-patroni
    /home/asarafanov/install-patroni[etcd]# scp * asarafanov@192.168.122.105:/home/asarafanov/install/python-patroni
    /home/asarafanov/install-patroni[etcd]# scp * asarafanov@192.168.122.105:/home/asarafanov/install/python-patroni

#### 4.3. Установка пакетов Patroni (на все ноды кластера).

    python3 -m pip install psutil --no-index --find-links file:///home/asarafanov/install/python-patroni/
    python3 -m pip install setuptools --no-index --find-links file:///home/asarafanov/install/python-patroni/ - при установке получил сообщение - Requirement already satisfied: setuptools in /usr/lib/python3/dist-packages
    python3 -m pip install wheel --no-index --find-links file:///home/asarafanov/install/python-patroni/
- при установке получил сообщение - Requirement already satisfied: wheel in /usr/lib/python3/dist-packages
    python3 -m pip install psycopg2-binary --no-index --find-links file:///home/asarafanov/install/python-patroni/
    python3 -m pip install patroni[etcd] --no-index --find-links file:///home/asarafanov/install/python-patroni/

Проверяем что установилось:

    root@astra-patroni01:~# patroni --version
    patroni 2.1.1
    root@astra-patroni01:~# 

    root@astra-patroni02:~# patroni --version
    patroni 2.1.1
    root@astra-patroni02:~# 

    root@astra-patroni03:~# patroni --version
    patroni 2.1.1
    root@astra-patroni03:~# 
    

### 5. Конфигурирование и запуск кластера Patroni.

#### 5.1. Создание каталога и назначение владельца (на всех нодах кластера).

    
    root@astra-patroni01:~# mkdir /etc/patroni; chown postgres:postgres /etc/patroni; chmod 700 /etc/patroni

#### 5.2. Создание конфигурационного файла patroni.yml

##### 5.2.1. Пример файла patroni.yaml

Описание параметров которые надо заполнить в примере:
    <HOSTNAME> - Имя узла.

    <NAMESPACE IN ETCD> - URL в кластере etcd. Обычно используется имя кластера.

    <CLUSTER NAME> - Имя кластера в etcd.

    <ETCD root pass> - Пароль созданного юзера в etcd.

    <USER_1C pass> - Пароль для нового юзера 1с в postgres.

    <Postgres password> - Пароль юзера postgres.

    <Replicator password> - Пароль юзера Replicator.

    <Rewind password> - Пароль юзера rewind_user.





