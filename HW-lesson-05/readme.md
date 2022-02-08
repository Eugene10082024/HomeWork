## ДЗ к занятию 5 

1. vagrant up должен поднимать 2 виртуалки: сервер и клиент на сервер должна быть расшарена директория на клиента она должна автоматически монтироваться при старте (fstab или autofs).

В шаре должна быть папка upload с правами на запись

    требования для NFS: NFSv3 по UDP, включенный firewall


## Настройка NFS сервера.

### 1.1. Разворачиваем следующие пакеты 
CentOS:
	yum install nfs-utils nfs-utils-lib -y
Astra Linux
	apt install nfs_kernel-server

### 1.2. Проверяем и при необходимости включаем следующие службы: rpcbind, nfs-server, nfs-lock, nfs-idmap

        [root@nfsserver ~]#systemctl status rpcbind
        ● rpcbind.service - RPC bind service
        Loaded: loaded (/usr/lib/systemd/system/rpcbind.service; enabled; vendor preset: enabled)
        Active: active (running) since Fri 2021-05-14 11:39:00 UTC; 28min ago
        Main PID: 373 (rpcbind)
        CGroup: /system.slice/rpcbind.service
                └─373 /sbin/rpcbind -w

        May 14 11:38:59 localhost.localdomain systemd[1]: Starting RPC bind service...
        May 14 11:39:00 localhost.localdomain systemd[1]: Started RPC bind service.

        [root@nfsserver ~]#systemctl status nfs-server
        ● nfs-server.service - NFS server and services
        Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; disabled; vendor preset: disabled)
        Active: inactive (dead)
        
        [root@nfsserver ~]#systemctl enable nfs-server
        Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
        [root@nfsserver ~]# sudo systemctl start nfs-server


        [root@nfsserver ~]# systemctl status nfs-lock
        ● rpc-statd.service - NFS status monitor for NFSv2/3 locking.
        Loaded: loaded (/usr/lib/systemd/system/rpc-statd.service; static; vendor preset: disabled)
        Active: active (running) since Вс 2021-05-16 15:25:19 UTC; 37s ago
        Main PID: 13035 (rpc.statd)
        CGroup: /system.slice/rpc-statd.service
                └─13035 /usr/sbin/rpc.statd


        [root@nfsserver ~]#systemctl status nfs-idmap
        ● nfs-idmapd.service - NFSv4 ID-name mapping service
        Loaded: loaded (/usr/lib/systemd/system/nfs-idmapd.service; static; vendor preset: disabled)
        Active: active (running) since Fri 2021-05-14 12:07:58 UTC; 47s ago
        Main PID: 12835 (rpc.idmapd)
        CGroup: /system.slice/nfs-idmapd.service
                └─12835 /usr/sbin/rpc.idmapd

        May 14 12:07:58 nfsserver systemd[1]: Starting NFSv4 ID-name mapping service...
        May 14 12:07:58 nfsserver systemd[1]: Started NFSv4 ID-name mapping service.


### 1.3. Создаем папку которой будет предоставляться доступ и папка upload с правами (w,r) с клиента NFS.
        mkdir -p /mnt/share/upload
        chmod -R 777 /mnt/share/
	

### 1.4. Добаляем папку в файл конфигурации nfs server /etc/exports	
        /mnt/share 192.168.11.102(rw,sync,no_root_squash,no_all_squash)
        где:
            /mnt/share – расшариваемая директория
            192.168.11.102 – IP адрес клиента 
            rw – разрешение на запись
            sync – синхронизация указанной директории
            no_root_squash – включение root привилегий
            no_all_squash — включение пользовательской авторизации

### 1.5. Выполняем перезагрузку конфигурационного файла и nfs-server
        exportfs -r
        systemctl restart nfs-server

### 1.6. Выполняем включение и настройку firewalld

        [root@nfsserver ~]# systemctl start firewalld
        [root@nfsserver ~]# systemctl enable firewalld
        Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
        Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.

### 1.7. Открываем необходимые порты на firewalld:	
        [root@nfsserver ~]# firewall-cmd --permanent --zone=public --add-service=nfs
        success
        [root@nfsserver ~]# firewall-cmd --permanent --zone=public --add-service=mountd
        success
        [root@nfsserver ~]# firewall-cmd --permanent --zone=public --add-service=rpc-bind
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=111/tcp
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=20048/tcp
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=4001/tcp
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=4001/udp
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=2049/udp
        success
        [root@nfsserver ~]# firewall-cmd --permanent --add-port=2049/tcp
        success

### 1.8. Перечитываем конфигурацию firewalld	
        [root@nfsserver ~]# firewall-cmd --reload
        success

### 1.9 Выполняем команду чтобы изменения сохранились        
    firewall-cmd --runtime-to-permanent

## 2. Настройка NFS на стороне клиента
### 2.1.Устанавливаем на клиете пакет, необходимый для работы NFS
    [root@nfsclient ~]# yum install nfs-utils -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
    * base: centos-mirror.rbc.ru
    * extras: mirror.reconn.ru
    * updates: mirror.reconn.ru
    Package 1:nfs-utils-1.3.0-0.68.el7.x86_64 already installed and latest version
    Nothing to do

Пакет установлен

### 2.2. Проверяем запущен ли сервис rpcbind не обходимый для работы с nfs.
    [root@nfsclient ~]# systemctl status rpcbind
     ● rpcbind.service - RPC bind service
     Loaded: loaded (/usr/lib/systemd/system/rpcbind.service; enabled; vendor preset: enabled)
     Active: active (running) since Вс 2021-05-16 15:04:44 UTC; 28min ago
     Main PID: 367 (rpcbind)
     CGroup: /system.slice/rpcbind.service
             └─367 /sbin/rpcbind -w

Сервис запущен и работает.

### 2.3. Создаем точку монтирования nfs на клиенте.

    [root@nfsclient ~]# mkdir /mnt/nfs-share

### 2.4. Выполняем ручное монтирование каталога NFS на клиенте по udp.

[root@nfsclient ~]# mount -t nfs 192.168.11.101:/mnt/share /mnt/nfs-share/ -o udp

### 2.5. Проверяем смонтировалась ли nfs папка.

[root@nfsclient ~]# mount | grep 192.168.11.101
192.168.11.101:/mnt/share on /mnt/nfs-share type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.11.101,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.11.101)

Да смонтировалась.

### 2.6. Дополнительно проверем работает ли nfs каталог под пользователем vagrant.
    [vagrant@nfsclient ~]$ cd /mnt/nfs-share/upload/
    [vagrant@nfsclient upload]$ touch test-01
    [vagrant@nfsclient upload]$ ls -al
    total 0
    drwxrwxrwx. 2 root    root    36 май 16 16:11 .
    drwxrwxrwx. 3 root    root    20 май 16 15:27 ..
    -rwxrwxrwx. 1 root    root     0 май 16 15:50 my-file
    -rw-rw-r--. 1 vagrant vagrant  0 май 16 16:11 test-01
    
Да, есть возможность созавать и работать с файлами.    


### 2.7. Добавляем запись к файл /etc/fstab для монтирования созданной nfs на клиенте.
    vi /etc/fstab 
    #
    # /etc/fstab
    # Created by anaconda on Thu Apr 30 22:04:55 2020
    UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
    /swapfile none swap defaults 0 0
    192.168.11.101:/mnt/share /mnt/nfs-share        nfs     noauto,x-systemd.automount,rw,sync,hard,intr,nfsvers=3,udp    0       0
    
Сохраняем изменения

### 2.9. Перезагружаем ВМ. После входа выполняем проверку подключения nfs.
    [vagrant@nfsclient ~]$ df -h
    Filesystem      Size  Used Avail Use% Mounted on
    devtmpfs        489M     0  489M   0% /dev
    tmpfs           496M     0  496M   0% /dev/shm
    tmpfs           496M  6,7M  489M   2% /run
    tmpfs           496M     0  496M   0% /sys/fs/cgroup
    /dev/sda1        40G  3,7G   37G  10% /
    tmpfs           100M     0  100M   0% /run/user/1000

NFS каталог не примонтировался при загрузке. Однако он примонтируется при первом входе в точку монтирования.    
 
    [vagrant@nfsclient ~]$ cd /mnt/nfs-share/
   
    [vagrant@nfsclient nfs-share]$ ls -al
    total 4
    drwxrwxrwx. 3 root root   20 май 16 15:27 .
    drwxr-xr-x. 3 root root   23 май 16 15:36 ..
    drwxrwxrwx. 2 root root 4096 май 16 16:34 upload
    
### 2.10 Проверяем наличие NFS каталога на nfsclient.

    [vagrant@nfsclient nfs-share]$ df -h
    Filesystem                 Size  Used Avail Use% Mounted on
    devtmpfs                   489M     0  489M   0% /dev
    tmpfs                      496M     0  496M   0% /dev/shm
    tmpfs                      496M  6,7M  489M   2% /run
    tmpfs                      496M     0  496M   0% /sys/fs/cgroup
    /dev/sda1                   40G  3,7G   37G  10% /
    tmpfs                      100M     0  100M   0% /run/user/1000
    192.168.11.101:/mnt/share   40G  3,7G   37G  10% /mnt/nfs-share

NFS появился.

















