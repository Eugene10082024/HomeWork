## ДЗ к Занятию 39

MySQL: Backup + Репликация

### Задания

1. В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы: bookmaker, competition, market, odds, outcome

2. Настроить GTID репликацию x варианты которые принимаются к сдаче

3. рабочий вагрантафайл

4. скрины или логи SHOW TABLES, конфиги

5. пример в логе изменения строки и появления строки на реплике

### Выполнение задания.

#### 1. Создание виртуальных машин mastermysql и slavesqlmy01 выполняется с помощью vagrant файла - vagrantfile. Для этого необходимо выполнить команду:

        vagrant up
        
Для подготовки к работе репликации на обеих ВМ   необходимо выполнить соответствующие playbook.

Способ 1.

Playbook выполняется с отдельной ВМ которую можно развернуть из файла vagrant_ansible.

После развертывания ВМ необходимо дополнительно выполнить: создание ssh ключ для пользователя ansible, скопировать ключ  на mastermysql и slavesqlmy01.

Команды для создания и копирования ключа приведены ниже.

        ssh-keygen
        
        ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.11.250

        ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@192.168.11.251

также под пользователем ansible выполнить команду:

        ansible-galaxy collection install community.mysql

После настройки управляющей ВМ  запускать playbook для подготовки mastermysql и slavesqlmy01 по настройке репликации.

    ansible-playbook master-mysql.yml

    ansible-playbook slave-mysql.yml

Способ 2.

Расскомментировать следующие строки в файле vagrantfile:
	
	config.vm.provision "ansible" do |ansible|
        ansible.verbose = "vvv"
        ansible.playbook = "provisioning/playbook.yml"
        ansible.become = "true"
	end

Выполнить команду:

    vagrant provision
    
Для правильной работы playbook в каталоге где размещен vagrant файл создания mastermysql и slavesqlmy01 необходимо создать каталог Dumps в который поместить файл bet.dmp. 

Также в этом каталоге будет создан файл master.sql

После выполнения playbook  подключаемся к каждой ВМ и выполняем проверки согласно методички.

#### 2. Проверка на ВМ mastermysql

    vagrant ssh mastermysql
    
    [root@mastermysql ~]# mysql -u root -p
    Enter password: Qwerty@12
    mysql>
    
2.1. Проверяем создание пользователя repl и назначение ему соответствующих прав.

    mysql> SELECT User,Host FROM mysql.user;
    +---------------+-----------+
    | User          | Host      |
    +---------------+-----------+
    | repl          | %         |
    | root          | %         |
    | root          | 127.0.0.1 |
    | mysql.session | localhost |
    | mysql.sys     | localhost |
    | root          | localhost |
    +---------------+-----------+
    6 rows in set (0,00 sec)

Из вывода видно что создан пользователь для репликации - repl

    mysql> show grants for repl@"%";
    +----------------------------------------------+
    | Grants for repl@%                            |
    +----------------------------------------------+
    | GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' |
    +----------------------------------------------+
    1 row in set (0,00 sec)
Права на выполнения репликации предоставлены.

2.2.  Проверяем атрибут server-id на мастер-сервере, он должен отличаться от такого же адрибута на slave сервере. Пока запоминает.

    mysql> SELECT @@server_id;
    +-------------+
    | @@server_id |
    +-------------+
    |           1 |
    +-------------+
     row in set (0,00 sec)

2.3. Проверяем что gtid включен.

    mysql>  SHOW VARIABLES LIKE 'gtid_mode';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | gtid_mode     | ON    |
    +---------------+-------+
    1 row in set (0,05 sec)

2.4. Проверяем создание базы данных bet и импорт из dump файла таблицы

    mysql> USE bet;
    Database changed
    mysql> show tables;
    +------------------+
    | Tables_in_bet    |
    +------------------+
    | bookmaker        |
    | competition      |
    | events_on_demand |
    | market           |
    | odds             |
    | outcome          |
    | v_same_event     |
    +------------------+
    7 rows in set (0,00 sec)
    
БД создана, таблицы имортированы


2.5. Проверяем наличие файла master.sql в каталоге /vagrant/Dumps/

    [root@mastermysql ~]# ls -al /vagrant/Dumps/
    total 1092
    drwxr-xr-x. 1 vagrant vagrant   4096 окт 12 05:02 .
    drwxr-xr-x. 1 vagrant vagrant   4096 окт 12 05:04 ..
    -rw-r--r--. 1 vagrant vagrant 117778 фев 27  2019 bet.dmp
    -rw-r--r--. 1 vagrant vagrant 991133 окт 12 04:57 master.sql
    
Файл создан, размер >0


#### 3. Проверка на ВМ slavemysql01
2.2.  Проверяем атрибут server-id на мастер-сервере, он должен отличаться от такого же адрибута на slave сервере. Пока запоминает.

    mysql> SELECT @@server_id;
    +-------------+
    | @@server_id |
    +-------------+
    |           2 |
    +-------------+
     row in set (0,00 sec)

2.3. Проверяем что gtid включен.

    mysql>  SHOW VARIABLES LIKE 'gtid_mode';
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | gtid_mode     | ON    |
    +---------------+-------+
    1 row in set (0,05 sec)
    
    
#### 4. Включение  репликации

4.1. Заливаем на slave сервер dump созданный ранее:

    SOURCE /vagrant/Dumps/master.sql
    
4.2. Выполнил команду (как в методичке)
    CHANGE MASTER TO MASTER_HOST = "192.168.11.250", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "Linux@2021", MASTER_AUTO_POSITION = 1;

4.3. Выполняем команду.
    start slave

4.4. Выполняем проверку - имеем ERROR    
    mysql> show status slave \G;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'slave' at line 1
ERROR: 
No query specified

mysql> show slave status \G;

                *************************** 1. row ***************************
                               Slave_IO_State: Waiting for master to send event
                                  Master_Host: 192.168.11.250
                                  Master_User: repl
                                  Master_Port: 3306
                                Connect_Retry: 60
                              Master_Log_File: mysql-bin.000002
                          Read_Master_Log_Pos: 120002
                               Relay_Log_File: slavemysql01-relay-bin.000002
                                Relay_Log_Pos: 611
                        Relay_Master_Log_File: mysql-bin.000002
                             Slave_IO_Running: Yes
                            Slave_SQL_Running: No
                              Replicate_Do_DB: 
                          Replicate_Ignore_DB: 
                           Replicate_Do_Table: 
                       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
                      Replicate_Wild_Do_Table: 
                  Replicate_Wild_Ignore_Table: 
                                   Last_Errno: 1396
                                   Last_Error: Error 'Operation CREATE USER failed for 'root'@'127.0.0.1'' on query. Default database: ''. Query: 'CREATE USER 'root'@'127.0.0.1' IDENTIFIED WITH 'mysql_native_password' AS '*95CE0B760C5EC64D41A3514438EBF9923617ED0C''
                                 Skip_Counter: 0
                          Exec_Master_Log_Pos: 398
                              Relay_Log_Space: 120429
                              Until_Condition: None
                               Until_Log_File: 
                                Until_Log_Pos: 0
                           Master_SSL_Allowed: No
                           Master_SSL_CA_File: 
                           Master_SSL_CA_Path: 
                              Master_SSL_Cert: 
                            Master_SSL_Cipher: 
                               Master_SSL_Key: 
                        Seconds_Behind_Master: NULL
                Master_SSL_Verify_Server_Cert: No
                                Last_IO_Errno: 0
                                Last_IO_Error: 
                               Last_SQL_Errno: 1396
                               Last_SQL_Error: Error 'Operation CREATE USER failed for 'root'@'127.0.0.1'' on query. Default database: ''. Query: 'CREATE USER                                          'root'@'127.0.0.1' IDENTIFIED WITH 'mysql_native_password' AS '*95CE0B760C5EC64D41A3514438EBF9923617ED0C''
                  Replicate_Ignore_Server_Ids: 
                             Master_Server_Id: 1
                                  Master_UUID: d7b4816b-2d8b-11ec-ac9f-5254004d77d3
                             Master_Info_File: /var/lib/mysql/master.info
                                    SQL_Delay: 0
                          SQL_Remaining_Delay: NULL
                      Slave_SQL_Running_State: 
                           Master_Retry_Count: 86400
                                  Master_Bind: 
                      Last_IO_Error_Timestamp: 
                     Last_SQL_Error_Timestamp: 211015 13:49:41
                               Master_SSL_Crl: 
                           Master_SSL_Crlpath: 
                           Retrieved_Gtid_Set: d7b4816b-2d8b-11ec-ac9f-5254004d77d3:1-41
                            Executed_Gtid_Set: d7b4816b-2d8b-11ec-ac9f-5254004d77d3:1,
                e794b018-2d9b-11ec-b81e-5254004d77d3:1-2
                                Auto_Position: 1
                         Replicate_Rewrite_DB: 
                                 Channel_Name: 
                           Master_TLS_Version: 
                1 row in set (0,00 sec)

                ERROR: 
                No query specified


Побороть ошибку не получилось. Поэтому выполнил следующие действия.

4.5. На mastermysql выполняю команду:

                  mysql> show master status;
                      
                  +------------------+----------+--------------+------------------+-------------------------------------------+
                  | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
                  +------------------+----------+--------------+------------------+-------------------------------------------+
                  | mysql-bin.000002 |   120002 |              |                  | d7b4816b-2d8b-11ec-ac9f-5254004d77d3:1-41 |
                  +------------------+----------+--------------+------------------+-------------------------------------------+
                   1 row in set (0,00 sec)

4.6. Останавливаем репликацию и выполняем некоторые монипуляции.
        stop slave
                
        change master to master_auto_position=0;
        
        CHANGE MASTER TO MASTER_HOST = "192.168.11.250", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "Linux@2021", MASTER_LOG_FILE = 'mysql-bin.000002', MASTER_LOG_POS = 120002;
где:
Значения MASTER_LOG_FILE и MASTER_LOG_POS бирем из п. 4.5

4.7. Выполняем команду;
    start slave;
    Query OK, 0 rows affected (0,01 sec)

Репликация работает.

                mysql> show slave status \G;
                *************************** 1. row ***************************
                               Slave_IO_State: Waiting for master to send event
                                  Master_Host: 192.168.11.250
                                  Master_User: repl
                                  Master_Port: 3306
                                Connect_Retry: 60
                              Master_Log_File: mysql-bin.000002
                          Read_Master_Log_Pos: 120002
                               Relay_Log_File: slavemysql01-relay-bin.000002
                                Relay_Log_Pos: 320
                        Relay_Master_Log_File: mysql-bin.000002
                             Slave_IO_Running: Yes
                            Slave_SQL_Running: Yes
                              Replicate_Do_DB: 
                          Replicate_Ignore_DB: 
                           Replicate_Do_Table: 
                       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
                      Replicate_Wild_Do_Table: 
                  Replicate_Wild_Ignore_Table: 
                                   Last_Errno: 0
                                   Last_Error: 
                                 Skip_Counter: 0
                          Exec_Master_Log_Pos: 120002
                              Relay_Log_Space: 534
                              Until_Condition: None
                               Until_Log_File: 
                                Until_Log_Pos: 0
                           Master_SSL_Allowed: No
                           Master_SSL_CA_File: 
                           Master_SSL_CA_Path: 
                              Master_SSL_Cert: 
                            Master_SSL_Cipher: 
                               Master_SSL_Key: 
                        Seconds_Behind_Master: 0
                Master_SSL_Verify_Server_Cert: No
                                Last_IO_Errno: 0
                                Last_IO_Error: 
                               Last_SQL_Errno: 0
                               Last_SQL_Error: 
                  Replicate_Ignore_Server_Ids: 
                             Master_Server_Id: 1
                                  Master_UUID: d7b4816b-2d8b-11ec-ac9f-5254004d77d3
                             Master_Info_File: /var/lib/mysql/master.info
                                    SQL_Delay: 0
                          SQL_Remaining_Delay: NULL
                      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
                           Master_Retry_Count: 86400
                                  Master_Bind: 
                      Last_IO_Error_Timestamp: 
                     Last_SQL_Error_Timestamp: 
                               Master_SSL_Crl: 
                           Master_SSL_Crlpath: 
                           Retrieved_Gtid_Set: 
                            Executed_Gtid_Set: a3cc6664-2dc2-11ec-aafd-5254004d77d3:1-2
                                Auto_Position: 0
                         Replicate_Rewrite_DB: 
                                 Channel_Name: 
                           Master_TLS_Version: 
                1 row in set (0,00 sec)

                ERROR: 
                No query specified

Еще раз проверяем, что gtid включен на slavemysql01.

            mysql>  SHOW VARIABLES LIKE 'gtid_mode';

            +---------------+-------+
            | Variable_name | Value |
            +---------------+-------+
            | gtid_mode     | ON    |
            +---------------+-------+
            1 row in set (0,05 sec)

4.8. Проверяем наличие БД bet на slavemysql01.
            mysql> use bet
            Database changed
            mysql> show tables;
            
            +---------------+
            | Tables_in_bet |
            +---------------+
            | bookmaker     |
            | competition   |
            | market        |
            | odds          |
            | outcome       |
            +---------------+
            5 rows in set (0,00 sec)

необходимые таблицы перенесены.

#### 5. Проверка работы репликации
 5.1. На сервре mastermysql добавляем несколько записей в таблицу -  bookmaker
 
    mysql> use bet;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    mysql>  INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
    Query OK, 1 row affected (0,00 sec)

mysql> SELECT * FROM bookmaker;

    +----+----------------+
    | id | bookmaker_name |
    +----+----------------+
    |  1 | 1xbet          |
    |  4 | betway         |
    |  5 | bwin           |
    |  6 | ladbrokes      |
    |  3 | unibet         |
    +----+----------------+
    5 rows in set (0,00 sec)

Добавлена запись с id=1 и bookmaker_name=1xbet

5.2 Проверяем что изменилось на сервере slavemysql01

    mysql> use bet;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    mysql> SELECT * FROM bookmaker; 
    +----+----------------+
    | id | bookmaker_name |
    +----+----------------+
    |  1 | 1xbet          |
    |  4 | betway         |
    |  5 | bwin           |
    |  6 | ladbrokes      |
    |  3 | unibet         |
    +----+----------------+
    5 rows in set (0,00 sec)

Также появилась запись с id=1 и bookmaker_name=1xbet

5.3. Добавим еще одну запись в таблицу bookmaker БД bet сервера mastermysql

    INSERT INTO bookmaker (id,bookmaker_name) VALUES(7,'Linux2021');

Имеем на сервере mastermysql:
    mysql>     INSERT INTO bookmaker (id,bookmaker_name) VALUES(7,'Linux2021');
    
    Query OK, 1 row affected (0,00 sec)

    mysql> SELECT * FROM bookmaker;
    +----+----------------+
    | id | bookmaker_name |
    +----+----------------+
    |  1 | 1xbet          |
    |  4 | betway         |
    |  5 | bwin           |
    |  6 | ladbrokes      |
    |  7 | Linux2021      |
    |  3 | unibet         |
    +----+----------------+
    6 rows in set (0,00 sec)

Смотрим на сервере slavemysql01

    mysql> SELECT * FROM bookmaker;
    +----+----------------+
    | id | bookmaker_name |
    +----+----------------+
    |  1 | 1xbet          |
    |  4 | betway         |
    |  5 | bwin           |
    |  6 | ladbrokes      |
    |  7 | Linux2021      |
    |  3 | unibet         |
    +----+----------------+
    6 rows in set (0,00 sec)

Запись появилась на обоих серврерах.

Репликация работает.

5.4.Дополнительно смотрим соедержание файлmysql-bin.000003 на сервере slavemysql01

    mysqlbinlog mysql-bin.000003

На скрин-шоте выделены действия по добавлению записей вводимых на сервере mastermysql01.







