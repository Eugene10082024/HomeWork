
##	1.Сборка nginx из исходных кодов.
### 1.1. Устанавливаем доп. пакеты.
	yum install -y rpm-build rpmdevtools yum-utils openssl-devel zlib-devel pcre-devel redhat-lsb-core createrepo
	  

### 1.2. создадим пользователя builder. Опция -m сразу создаст домашний каталог для пользователя.
	[root@vmrepo ~]# useradd builder -m

### 1.3. Заходим под пользователем builder
	[root@vmrepo ~]# su - builder

### 1.4. Создадим структуру каталогов для сборки и посмотрим что создано:
	[builder@vmrepo ~]$ rpmdev-setuptree
	[builder@vmrepo ~]$ ls -al rpmbuild/
	total 0
	drwxrwxr-x. 7 builder builder 72 May 20 09:20 .
	drwx------. 3 builder builder 96 May 20 09:20 ..
	drwxrwxr-x. 2 builder builder  6 May 20 09:20 BUILD
	drwxrwxr-x. 2 builder builder  6 May 20 09:20 RPMS
	drwxrwxr-x. 2 builder builder  6 May 20 09:20 SOURCES
	drwxrwxr-x. 2 builder builder  6 May 20 09:20 SPECS
	drwxrwxr-x. 2 builder builder  6 May 20 09:20 SRPMS

### 1.5. Выполняем дополнительные действия под root.
	[root@vmrepo SRC]# mount.cifs //10.60.32.55/10-dir_linux /mnt/windows -o user=a.sarafanov

### 1.6. Копируем файл   nginx-1.19.10-1.el7.ngx.src.rpm из папки /mnt/windows/SRC в папку /home/builder и меняем владельца
	[root@vmrepo SRC]# cp /mnt/windows/SRC/nginx-1.19.10-1.el7.ngx.src.rpm /home/builder/
	[root@vmrepo SRC]# chown builder:builder /home/builder/nginx-1.19.10-1.el7.ngx.src.rpm
	 su - builder
	 
### 1.7. Установим скачанный исходник командой:
	rpm -Uvh nginx-1.19.10-1.el7.ngx.src.rpm

### 1.8. Проверяем наличие развернутого исходного кода в rpmbuild/SOURCES
	[builder@vmrepo ~]$ ls -al rpmbuild/SOURCES
	total 1092
	drwxrwxr-x. 2 builder builder    4096 May 20 09:31 .
	drwxrwxr-x. 7 builder builder      72 May 20 09:20 ..
	-rw-r--r--. 1 builder builder     351 Apr 13 18:48 logrotate
	-rw-r--r--. 1 builder builder 1061062 Apr 13 18:34 nginx-1.19.10.tar.gz
	-rwxr-xr-x. 1 builder builder     646 Apr 13 18:48 nginx.check-reload.sh
	-rw-r--r--. 1 builder builder     643 Apr 13 18:48 nginx.conf
	-rw-r--r--. 1 builder builder    1377 Apr 13 18:48 nginx.copyright
	-rw-r--r--. 1 builder builder     475 Apr 13 18:48 nginx-debug.service
	-rw-r--r--. 1 builder builder     148 Apr 13 18:48 nginx-debug.sysconf
	-rw-r--r--. 1 builder builder    1093 Apr 13 18:48 nginx.default.conf
	-rwxr-xr-x. 1 builder builder    3655 Apr 13 18:48 nginx.init.in
	-rw-r--r--. 1 builder builder     469 Apr 13 18:48 nginx.service
	-rw-r--r--. 1 builder builder     355 Apr 13 18:48 nginx.suse.logrotate
	-rw-r--r--. 1 builder builder      98 Apr 13 18:48 nginx.sysconf
	-rw-r--r--. 1 builder builder     906 Apr 13 18:48 nginx.upgrade.sh

### 1.9. Собираем установочный RPM-пакет:
	 rpmbuild -bb rpmbuild/SPECS/nginx.spec
	...
	Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.ybId6q
	+ umask 022
	+ cd /home/builder/rpmbuild/BUILD
	+ cd nginx-1.19.10
	+ /usr/bin/rm -rf /home/builder/rpmbuild/BUILDROOT/nginx-1.19.10-1.el7.ngx.x86_64
	+ exit 0

### 1.10. Сборка пакета завершена. Проверяем что получилось.
	[builder@vmrepo ~]$ ls -al rpmbuild/RPMS/x86_64/
	total 2584
	drwxr-xr-x. 2 builder builder     100 May 20 09:44 .
	drwxrwxr-x. 3 builder builder      20 May 20 09:44 ..
	-rw-rw-r--. 1 builder builder  810724 May 20 09:44 nginx-1.19.10-1.el7.ngx.x86_64.rpm
	-rw-rw-r--. 1 builder builder 1834012 May 20 09:44 nginx-debuginfo-1.19.10-1.el7.ngx.x86_64.rpm

### 1.11. Проверяем установлен nginx на данной ВМ
	[root@vmrepo SRC]# rpm -qa | grep nginx*
	[root@vmrepo SRC]#
	
	nginx не установлен.
	
### 1.12. Устанавливаем nginx на ВМ
	[root@vmrepo SRC]# rpm -ivh /home/builder/rpmbuild/RPMS/x86_64/nginx-1.19.10-1.el7.ngx.x86_64.rpm
	Preparing...                          ################################# [100%]
	Updating / installing...
	   1:nginx-1:1.19.10-1.el7.ngx        ################################# [100%]
	----------------------------------------------------------------------

	Thanks for using nginx!

### 1.13. Запускаем nginx и проверяем что он работает.
	[root@vmrepo SRC]# systemctl status nginx
	● nginx.service - nginx - high performance web server
	   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
	   Active: inactive (dead)
		 Docs: http://nginx.org/en/docs/
		 
	[root@vmrepo SRC]# systemctl start nginx
	
	[root@vmrepo SRC]# systemctl status nginx
	● nginx.service - nginx - high performance web server
	   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
	   Active: active (running) since Thu 2021-05-20 09:54:13 MSK; 2s ago
		 Docs: http://nginx.org/en/docs/
	  Process: 14321 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
	 Main PID: 14322 (nginx)
	   CGroup: /system.slice/nginx.service
			   ├─14322 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
			   └─14323 nginx: worker process


	[root@vmrepo SRC]# curl http://localhost
		<!DOCTYPE html>
		<html>
		<head>
		<title>Welcome to nginx!</title>
		<style>
			body {
				width: 35em;
				margin: 0 auto;
				font-family: Tahoma, Verdana, Arial, sans-serif;
			}
		</style>
		</head>
		<body>
		<h1>Welcome to nginx!</h1>
		<p>If you see this page, the nginx web server is successfully installed and
		working. Further configuration is required.</p>

		<p>For online documentation and support please refer to
		<a href="http://nginx.org/">nginx.org</a>.<br/>
		Commercial support is available at
		<a href="http://nginx.com/">nginx.com</a>.</p>

		<p><em>Thank you for using nginx.</em></p>
		</body>
		</html>
		[root@vmrepo SRC]#

Nginx работает.

### 1.14. Смотрим полное название установленного в системе пакета:
	[root@vmrepo SRC]# rpm -qa | grep nginx
	nginx-1.19.10-1.el7.ngx.x86_64

### 1.15. Удаляем установленный nginx с ВМ
	[root@vmrepo SRC]# rpm -e nginx-1.19.10-1.el7.ngx.x86_64
	[root@vmrepo SRC]# rpm -qa | grep nginx
	[root@vmrepo SRC]#
	su - builder

## 2. Сборка nginx с модулем OpenSSL.

### 2.1. Скачиваем и разархивируем крайнюю версию openssl.
	[builder@vmrepo ~]$ wget https://www.openssl.org/source/latest.tar.gz
	[builder@vmrepo ~]$ tar -xvf latest.tar.gz

Имеем:
	[builder@vmrepo ~]$ ls -al modules/
	total 4
	drwxrwxr-x.  4 builder builder   65 May 20 16:39 .
	drwx------.  5 builder builder  183 May 20 10:34 ..
	drwxrwxr-x. 19 builder builder 4096 May 20 16:33 openssl-1.1.1k
	drwxrwxr-x.  3 builder builder  152 May 20 10:33 spnego-http-auth-nginx-module


### 2.3. Редоктируем файл nginx.spec
	[builder@vmrepo ~] vi rpmbuild/SPECS/nginx.spec

Находим %build и добавляем --with-openssl=/home/builder/open-1.1.1k

Имеем:

	%build
	./configure %{BASE_CONFIGURE_ARGS} \
		--with-cc-opt="%{WITH_CC_OPT}" \
		--with-ld-opt="%{WITH_LD_OPT}" \
		--with-openssl=/home/builder/modules/openssl-1.1.1k \
		--with-debug

### 2.4. Выполняем сборку rpm пакета nginx с модулем openssl

	[builder@vmrepo ~]$ rpmbuild -bb rpmbuild/SPECS/nginx.spec
	Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.Ibl8VW
	+ umask 022
	+ cd /home/builder/rpmbuild/BUILD
	+ cd nginx-1.19.10
	+ /usr/bin/rm -rf /home/builder/rpmbuild/BUILDROOT/nginx-1.19.10-1.el7.ngx.x86_64
	+ exit 0

### 2.5. Пакет собран. Проверяем
	[builder@vmrepo ~]$ ls -al rpmbuild/RPMS/x86_64
	total 4104
	drwxr-xr-x. 2 builder builder     100 May 20 16:36 .
	drwxrwxr-x. 3 builder builder      20 May 20 09:44 ..
	-rw-rw-r--. 1 builder builder 2200036 May 20 16:36 nginx-1.19.10-1.el7.ngx.x86_64.rpm
	-rw-rw-r--. 1 builder builder 1996300 May 20 16:36 nginx-debuginfo-1.19.10-1.el7.ngx.x86_64.rpm

### 2.5. Устанавлиаем и запускаем nginx.
	[root@vmrepo x86_64]# rpm -ivh nginx-1.19.10-1.el7.ngx.x86_64.rpm
	Preparing...                          ################################# [100%]
	Updating / installing...
	   1:nginx-1:1.19.10-1.el7.ngx        ################################# [100%]

	[root@vmrepo x86_64]# systemctl start nginx
	
	[root@vmrepo x86_64]# systemctl status nginx
	● nginx.service - nginx - high performance web server
	   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
	   Active: active (running) since Thu 2021-05-20 16:47:43 MSK; 5s ago
		 Docs: http://nginx.org/en/docs/
	  Process: 14722 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
	 Main PID: 14723 (nginx)
	   CGroup: /system.slice/nginx.service
			   ├─14723 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
			   └─14724 nginx: worker process


## 3. Создание собственного репозитория.

В создаваемый репозиторий будем размещать следующие пакеты:

    [root@vmrepo rpm]# ls -al
    total 245196
    drwxr-xr-x. 2 vagrant vagrant      4096 май 20 18:56 .
    drwx------. 4 vagrant vagrant       106 май 20 18:55 ..
    -rw-rw-rw-. 1 vagrant vagrant  32224945 май 26  2015 1C_Enterprise83-common-8.3.6-2041.x86_64.rpm
    -rw-rw-rw-. 1 vagrant vagrant   1538272 май 26  2015 1C_Enterprise83-common-nls-8.3.6-2041.x86_64.rpm
    -rw-rw-rw-. 1 vagrant vagrant 161377345 май 26  2015 1C_Enterprise83-server-8.3.6-2041.x86_64.rpm
    -rw-rw-rw-. 1 vagrant vagrant  53525865 май 26  2015 1C_Enterprise83-server-nls-8.3.6-2041.x86_64.rpm
    -rw-rw-rw-. 1 vagrant vagrant    183312 май 26  2015 1C_Enterprise83-ws-8.3.6-2041.x86_64.rpm
    -rw-rw-rw-. 1 vagrant vagrant     15250 май 26  2015 1C_Enterprise83-ws-nls-8.3.6-2041.x86_64.rpm
    -rw-r--r--. 1 vagrant vagrant   2200036 май 20 18:44 nginx-1.19.10-1.el7.ngx.x86_64.rpm

### 3.1. Создаем каталог для репозитория.
    [root@vmrepo rpm]# mkdir -p /usr/share/nginx/html/repo

### 3.2. Копируем пакеты в репозиторий.
    [root@vmrepo rpm]# mkdir -p /usr/share/nginx/html/repo

### 3.3. Инициализируем репозиторий.

    createrepo /usr/share/nginx/html/repo/
    Spawning worker 0 with 7 pkgs
    Workers Finished
    Saving Primary metadata
    Saving file lists metadata
    Saving other metadata
    Generating sqlite DBs
    Sqlite DBs complete

### 3.4. Добавляем директиву autoindex в /etc/nginx/nginx.conf
        location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }

### 3.5. Проверяем измененную конфигурацию
    [root@vmrepo rpm]# nginx -t
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

### 3.6. Даем команду перечетать и применить измененную конфигурацию.
    [root@vmrepo rpm]# nginx -s reload

### 3.7. Проверяем.

    [root@vmrepo rpm]# curl -a  http://192.168.11.101/repo/
    <html>
    <head><title>Index of /repo/</title></head>
    <body>
    <h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
    <a href="repodata/">repodata/</a>                                          20-May-2021 19:04                   -
    <a href="1C_Enterprise83-common-8.3.6-2041.x86_64.rpm">1C_Enterprise83-common-8.3.6-2041.x86_64.rpm</a>       20-May-2021 19:00            32224945
    <a href="1C_Enterprise83-common-nls-8.3.6-2041.x86_64.rpm">1C_Enterprise83-common-nls-8.3.6-2041.x86_64.rpm</a>   20-May-2021 19:00             1538272
    <a href="1C_Enterprise83-server-8.3.6-2041.x86_64.rpm">1C_Enterprise83-server-8.3.6-2041.x86_64.rpm</a>       20-May-2021 19:00           161377345
    <a href="1C_Enterprise83-server-nls-8.3.6-2041.x86_64.rpm">1C_Enterprise83-server-nls-8.3.6-2041.x86_64.rpm</a>   20-May-2021 19:00            53525865
    <a href="1C_Enterprise83-ws-8.3.6-2041.x86_64.rpm">1C_Enterprise83-ws-8.3.6-2041.x86_64.rpm</a>           20-May-2021 19:00              183312
    <a href="1C_Enterprise83-ws-nls-8.3.6-2041.x86_64.rpm">1C_Enterprise83-ws-nls-8.3.6-2041.x86_64.rpm</a>       20-May-2021 19:00               15250
    <a href="nginx-1.19.10-1.el7.ngx.x86_64.rpm">nginx-1.19.10-1.el7.ngx.x86_64.rpm</a>                 20-May-2021 19:00             2200036
    </pre><hr></body>
    </html>

### 3.8. Создаем файл с описанием репозитория.
    [root@vmrepo rpm]# cat >> /etc/yum.repos.d/otus.repo << EOF 
    [otus]
    name=otus-linux
    baseurl=http://192.168.11.101/repo
    gpgcheck=0
    enabled=1
    EOF

## Подымаем вторую ВМ и проверяем установку пакетов.

    [root@vmrepo log]# ip addr
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 08:00:27:50:bc:a0 brd ff:ff:ff:ff:ff:ff
        inet 192.168.11.201/24 brd 192.168.11.255 scope global noprefixroute eth1
        valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fe50:bca0/64 scope link 
        valid_lft forever preferred_lft forever

       [root@vmrepo log]# yum repolist
        Загружены модули: fastestmirror
        Loading mirror speeds from cached hostfile
        * base: mirror.reconn.ru
        * extras: mirrors.datahouse.ru
        * updates: centos-mirror.rbc.ru
        Идентификатор репозитория       репозиторий`          состояние
        base/7/x86_64                  CentOS-7 - Base         10 072
        extras/7/x86_64                CentOS-7 - Extras        476
        otus                           otus-linux                7
        updates/7/x86_64               CentOS-7 - Updates      2 189
        repolist: 12 744
    
       
       
### Устанавливанию пакеты 1С сервера.

    yum install 1C_Enterprise*
    
    Общий размер                                                                                                                                                                                               116 MB/s | 237 MB  00:00:02     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
    Установка   : 1C_Enterprise83-common-8.3.6-2041.x86_64                                                                                                                                                                               1/6 
    Установка   : 1C_Enterprise83-server-8.3.6-2041.x86_64                                                                                                                                                                               2/6 
    Установка   : 1C_Enterprise83-ws-8.3.6-2041.x86_64                                                                                                                                                                                   3/6 
    Установка   : 1C_Enterprise83-ws-nls-8.3.6-2041.x86_64                                                                                                                                                                               4/6 
    Установка   : 1C_Enterprise83-server-nls-8.3.6-2041.x86_64                                                                                                                                                                           5/6 
    Установка   : 1C_Enterprise83-common-nls-8.3.6-2041.x86_64                                                                                                                                                                           6/6 
    Проверка    : 1C_Enterprise83-ws-nls-8.3.6-2041.x86_64                                                                                                                                                                               1/6 
    Проверка    : 1C_Enterprise83-server-8.3.6-2041.x86_64                                                                                                                                                                               2/6 
    Проверка    : 1C_Enterprise83-common-nls-8.3.6-2041.x86_64                                                                                                                                                                           3/6 
    Проверка    : 1C_Enterprise83-ws-8.3.6-2041.x86_64                                                                                                                                                                                   4/6 
    Проверка    : 1C_Enterprise83-server-nls-8.3.6-2041.x86_64                                                                                                                                                                           5/6 
    Проверка    : 1C_Enterprise83-common-8.3.6-2041.x86_64                                                                                                                                                                               6/6 

Установлено:
  1C_Enterprise83-common.x86_64 0:8.3.6-2041    1C_Enterprise83-common-nls.x86_64 0:8.3.6-2041    1C_Enterprise83-server.x86_64 0:8.3.6-2041    1C_Enterprise83-server-nls.x86_64 0:8.3.6-2041    1C_Enterprise83-ws.x86_64 0:8.3.6-2041 1C_Enterprise83-ws-nls.x86_64 0:8.3.6-2041   

    
### Проверяем статус сервиса 1С и запускаем его.
    [root@vmrepo log]# service srv1cv83 status
    1C:Enterprise 8.3 server status:
    Init script: NOT STARTED.
    [root@vmrepo log]# service srv1cv83 start
    Starting 1C:Enterprise 8.3 server: OK
    [root@vmrepo log]# service srv1cv83 status
    1C:Enterprise 8.3 server status:
    Init script: STARTED.
        Ragent: RUNNING.

    
    
    
    
    
    
    
    
    
    
    
    
    
    



