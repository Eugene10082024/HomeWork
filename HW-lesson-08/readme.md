## ДЗ к заданию 8

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);

2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi);

3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами; 4*. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.


## Выполнение п.1 ДЗ






## Выполнение п.2 ДЗ

### 2.1. Устанавливаем доступ к репозиторию epel-release.

	[root@localhost ~]# dnf install epel-release
 	 Running transaction
	  Preparing        :                                                                                                     1/1
	  Installing       : epel-release-8-8.el8.noarch                                                                         1/1
	  Running scriptlet: epel-release-8-8.el8.noarch                                                                         1/1
	  Verifying        : epel-release-8-8.el8.noarch                                                                         1/1

	Installed:
	  epel-release-8-8.el8.noarch

Complete!

### 2.2. Устанавливаем пакет spawn-fcgi
	
	[root@localhost ~]# dnf install -y spawn-fcgi

	Running transaction
	Preparing        :                                                                                                                                                                                                                     1/1
	Installing       : spawn-fcgi-1.6.3-17.el8.x86_64                                                                                                                                                                                      1/1
	Running scriptlet: spawn-fcgi-1.6.3-17.el8.x86_64                                                                                                                                                                                      1/1
	Verifying        : spawn-fcgi-1.6.3-17.el8.x86_64                                                                                                                                                                                      1/1

	Installed:
	spawn-fcgi-1.6.3-17.el8.x86_64

	Complete!

### 2.3. Устанавливаем доп пакеты для работы spawn-fcgi
	
	[root@localhost ~]# dnf install -y php php-cli mod_fcgid httpd

	Installed:
	  apr-1.6.3-11.el8.x86_64                           apr-util-1.6.1-6.el8.x86_64                           apr-util-bdb-1.6.1-6.el8.x86_64                                 apr-util-openssl-1.6.1-6.el8.x86_64
	  centos-logos-httpd-80.5-2.el8.noarch              httpd-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64    httpd-filesystem-2.4.37-30.module_el8.3.0+561+97fdbbcc.noarch   httpd-tools-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64
	  mailcap-2.1.48-3.el8.noarch                       mod_fcgid-2.3.9-16.el8.x86_64                         mod_http2-1.15.7-2.module_el8.3.0+477+498bb568.x86_64           nginx-filesystem-1:1.14.1-9.module_el8.0.0+184+e34fea82.noarch
	  php-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64   php-cli-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64   php-common-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64          php-fpm-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64

	Complete!
	[root@localhost ~]#

### 2.4. Редактируем конфиг файл /etc/sysconfig/spawn-fcgi



	[root@localhost ~] sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
	[root@localhost ~] sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

### 2.5. Создаем Unit /etc/systemd/system/spawn-fcgi.service

	[root@localhost ~] vi /etc/systemd/system/spawn-fcgi.service
	[Unit]
	Description=Spawn-fcgi startup service by Otus
	After=network.target
	[Service]
	Type=simple
	PIDFile=/var/run/spawn-fcgi.pid
	EnvironmentFile=/etc/sysconfig/spawn-fcgi
	ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
	KillMode=process
	[Install]
	WantedBy=multi-user.target



### 2.6. Перечтываем конфигурацию Units
	
	[root@localhost ~]# systemctl daemon-reload

### 2.7. Запускаем spawn-fcgi.service
	[root@localhost ~]# systemctl enable spawn-fcgi
	[root@localhost ~]# systemctl start spawn-fcgi

## 3.

### 3.1. Создаем Unit для запуска сервисов httpd.
		
		vi /etc/systemd/system/httpd@.service
		
		[Unit]
		Description=The Apache HTTP Server
		After=network.target remote-fs.target nss-lookup.target
		Documentation=man:httpd(8)
		Documentation=man:apachectl(8)
		[Service]
		Type=notify
		EnvironmentFile=/etc/sysconfig/httpd-%I
		ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
		ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
		ExecStop=/bin/kill -WINCH ${MAINPID}
		KillSignal=SIGCONT
		PrivateTmp=true
		[Install]
		WantedBy=multi-user.target

### 3.2. создаем конфигурационный файл для сервиса http@first
	
	vi /etc/sysconfig/httpd-first
	OPTIONS=-f conf/httpd-first.conf

### 3.2. создаем конфигурационный файл для сервиса http@second
	
	vi /etc/sysconfig/httpd-second
	OPTIONS=-f conf/httpd-second.conf
	
### 3.3. Копируем с gitHub конфигурационные файлы httpd-first.conf и httpd-second.conf.

### 3.4. Перечитываем 
systemctl daemon-reload
systemctl start httpd@first
systemctl start httpd@second








