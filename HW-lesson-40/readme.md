
## ДЗ к Занятию 40

MySQL: Backup + Репликация

### Задания

   1. Настроить hot_standby репликацию с использованием слотов
   
   2. Настроить правильное резервное копирование на базе barman

### Выполнение задания.

#### 1. Создание виртуальных машин masterpostgres и slavepostgres и пастройка репликации

##### 1.1. Создание ВМ выполняется с помощью vagrant файла - vagrantfile. Для этого необходимо выполнить команду:

        vagrant up
        
##### 1.2.Для настройки репликации необходимо выполнить  playbook - install.yml.

Переменные для работы playbook находятся в: /etc/ansible/inventories/group_vars

 pgdata_cls: /mnt/pgs-cluster - местонахождение файлов кластера postgrres

 user_replication: replicator - учетная запись пользователя под которой выполняется репликация

 password_replicator: Qwerty@12 - пароль учетной записи под которой выполняется репликация

 
Playbook можно выполнить 2 способами:

 Способ 1. 
 
 Выполняется с отдельной ВМ которую можно развернуть из файла vagrant_ansible.

 Для этого: 

После развертывания ВМ необходимо дополнительно создать ssh ключ для пользователя ansible, скопировать ключ  на mastermysql и slavesqlmy01.

Команды для создания и копирования ключа приведены ниже.


        ssh-keygen
        
        ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.11.240

        ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.11.241

После настройки ВМ ansible запустить playbook для подготовки для настройки репликации.

    ansible-playbook install.yml

Способ 2. 

Расскоментировать следующие строки в vagrantfile:
    
    config.vm.provision "ansible" do |ansible|
        ansible.verbose = "vvv"
        ansible.playbook = "provisioning/install.yml"
    end

После чего выполнить команду для выплнения playbook:
    
    vagrant provision 

    

#### 2. Проверка работы репликации.

##### 2.1. Выполнение проверок на master-сервере (masterpostgres)


    postgres=# \x
    
    Expanded display is on.
    
    postgres=# SELECT * FROM pg_replication_slots;
    -[ RECORD 1 ]-------+-----------
    slot_name           | pgstaindby
    plugin              | 
    slot_type           | physical
    datoid              | 
    database            | 
    temporary           | f
    active              | t
    active_pid          | 16965
    xmin                | 
    catalog_xmin        | 
    restart_lsn         | 0/3000148
    confirmed_flush_lsn | 
    wal_status          | reserved
    safe_wal_size       | 


    postgres=# SELECT * FROM pg_stat_replication;
    -[ RECORD 1 ]----+------------------------------
    pid              | 16965
    usesysid         | 16384
    usename          | replicator
    application_name | walreceiver
    client_addr      | 192.168.11.241
    client_hostname  | 
    client_port      | 57908
    backend_start    | 2021-10-19 16:25:31.651026+03
    backend_xmin     | 
    state            | streaming
    sent_lsn         | 0/3000148
    write_lsn        | 0/3000148
    flush_lsn        | 0/3000148
    replay_lsn       | 0/3000148
    write_lag        | 
    flush_lag        | 
    replay_lag       | 
    sync_priority    | 0
    sync_state       | async
    reply_time       | 2021-10-19 17:29:28.744501+03
    




##### 2.2, выполнение проверок на slave-сервере (slavepostgres) 

    postgres=# SELECT * FROM pg_stat_wal_receiver;
    -[ RECORD 1 ]-------------------------------------------------------------
    pid                   | 16991
    status                | streaming
    receive_start_lsn     | 0/3000000
    receive_start_tli     | 1
    written_lsn           | 0/3000148
    flushed_lsn           | 0/3000148
    received_tli          | 1
    last_msg_send_time    | 2021-10-19 17:35:08.929402+03
    last_msg_receipt_time | 2021-10-19 17:35:08.929359+03
    latest_end_lsn        | 0/3000148
    latest_end_time       | 2021-10-19 16:30:34.975015+03
    slot_name             | pgstaindby
    sender_host           | 192.168.11.240
    sender_port           | 5432
    conninfo              | user=replicator passfile=/root/.pgpass channel_binding=prefer dbname=replication host=192.168.11.240 port=5432 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any





##### 2.3. Создание БД и таблицы на masterpostgres и проверка их наличия на slavepostgres

##### Действия на masterpostges

    -bash-4.2$ psql
    psql (13.4)
    Type "help" for help.

    postgres=# \l
                                    List of databases
    Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
    -----------+----------+----------+-------------+-------------+-----------------------
    postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
    template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    (3 rows)

    
Создаем базу данных - test_repl
    
    postgres=# create database test_repl;
    CREATE DATABASE
    postgres=# \l
                                    List of databases
    Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
    -----------+----------+----------+-------------+-------------+-----------------------
    postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
    template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    test_repl | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
    (4 rows)

Создаем таблицу - test_repl

    postgres=# \c test_repl;
    You are now connected to database "test_repl" as user "postgres".
    test_repl=# CREATE TABLE table_test ( 
    test_repl(#     num     integer,
    test_repl(#     name    varchar(40) 
    test_repl(# );
    CREATE TABLE

Проверяем наличие созданной таблицы:

    test_repl=# \dt;
            List of relations
    Schema |    Name    | Type  |  Owner   
    --------+------------+-------+----------
    public | table_test | table | postgres
    (1 row)

Добавляем несколько строк в созданную таблицу;

    test_repl=# INSERT INTO table_test (num, name) VALUES (1, 'First');
    INSERT 0 1
    test_repl=# INSERT INTO table_test (num, name) VALUES (2, 'Second');
    INSERT 0 1
    test_repl=# INSERT INTO table_test (num, name) VALUES (3, 'Один');
    INSERT 0 1
    test_repl=# INSERT INTO table_test (num, name) VALUES (4, 'Два');
    INSERT 0 1

Проверяем наличие строк в таблице:

    test_repl=# select * from table_test;
    num |  name  
    -----+--------
    1 | First
    2 | Second
    3 | Один
    4 | Два
    (4 rows)

##### Проверям наличие базы данных, таблицы и значений создаваемых на masterpostgres на slavemaster.

    postgres=# \l
                                    List of databases
    Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
    -----------+----------+----------+-------------+-------------+-----------------------
    postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
    template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
    test_repl | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
    (4 rows)

База данных test_repl создана

    postgres=# \c test_repl;
    You are now connected to database "test_repl" as user "postgres".

    test_repl=# \dt;
            List of relations
    Schema |    Name    | Type  |  Owner   
    --------+------------+-------+----------
    public | table_test | table | postgres
    (1 row)

Таблица table_test создана

    test_repl=# select * from table_test;
    num |  name  
    -----+--------
    1 | First
    2 | Second
    3 | Один
    4 | Два
    (4 rows)

Данные перенесены.






