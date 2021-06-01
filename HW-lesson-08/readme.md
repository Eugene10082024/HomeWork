## ДЗ к заданию 8

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);

2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi);

3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами; 4*. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.

Информация:
	В папке HomeWork/HW-lesson-08/ создана папка conf_files в которой размещены конфигурационные файлы используемые для выполнения ДЗ путем развертывания ВМ с необходимыми компонентами через Vagrantfile файл.
	

## Выполнение п.1 ДЗ


	[root@vmtest ~]# systemctl status findword.service
	
	● findword.service - Find word in file
	   Loaded: loaded (/etc/systemd/system/findword.service; enabled; vendor preset: disabled)
	   Active: inactive (dead) since Tue 2021-06-01 14:15:40 MSK; 29s ago
	  Process: 19889 ExecStart=/usr/local/bin/findword.sh $KEY $FILE (code=exited, status=0/SUCCESS)
	 Main PID: 19889 (code=exited, status=0/SUCCESS)

	Jun 01 14:15:40 vmtest systemd[1]: Starting Find word in file...
	Jun 01 14:15:40 vmtest systemd[1]: findword.service: Succeeded.
	Jun 01 14:15:40 vmtest systemd[1]: Started Find word in file.

	[root@vmtest ~]# systemctl status findword.timer
	
	● findword.timer
	   Loaded: loaded (/etc/systemd/system/findword.timer; enabled; vendor preset: disabled)
	   Active: active (waiting) since Tue 2021-06-01 13:15:33 MSK; 1h 1min ago
	  Trigger: Tue 2021-06-01 14:17:41 MSK; 24s left

	Jun 01 13:15:33 vmtest systemd[1]: Started findword.timer.
	Jun 01 13:15:34 vmtest systemd[1]: /etc/systemd/system/findword.timer:2: Unknown lvalue 'Destription' in section 'Unit'
	Jun 01 13:15:34 vmtest systemd[1]: /etc/systemd/system/findword.timer:2: Unknown lvalue 'Destription' in section 'Unit'
	Jun 01 13:15:34 vmtest systemd[1]: /etc/systemd/system/findword.timer:2: Unknown lvalue 'Destription' in section 'Unit'
	Jun 01 13:15:36 vmtest systemd[1]: /etc/systemd/system/findword.timer:2: Unknown lvalue 'Destription' in section 'Unit'



	[root@vmtest ~]# journalctl -f -u findword.service
	
	Jun 01 14:19:36 vmtest systemd[1]: findword.service: Succeeded.
	Jun 01 14:19:37 vmtest systemd[1]: Started Find word in file.
	Jun 01 14:20:11 vmtest systemd[1]: Starting Find word in file...
	Jun 01 14:20:11 vmtest findword.sh[20040]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/baseos-31c79d9833c65cf7/packages/centos-logos-httpd-80.5-2.el8.noarch.rpm removed
	Jun 01 14:20:11 vmtest findword.sh[20040]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-tools-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64.rpm removed
	Jun 01 14:20:11 vmtest findword.sh[20040]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-filesystem-2.4.37-30.module_el8.3.0+561+97fdbbcc.noarch.rpm removed
	Jun 01 14:20:11 vmtest findword.sh[20040]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64.rpm removed
	Jun 01 14:20:11 vmtest systemd[1]: findword.service: Succeeded.
	Jun 01 14:20:11 vmtest systemd[1]: Started Find word in file.
	Jun 01 14:20:41 vmtest systemd[1]: Starting Find word in file...
	Jun 01 14:20:41 vmtest findword.sh[20043]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/baseos-31c79d9833c65cf7/packages/centos-logos-httpd-80.5-2.el8.noarch.rpm removed
	Jun 01 14:20:41 vmtest findword.sh[20043]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-tools-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64.rpm removed
	Jun 01 14:20:41 vmtest findword.sh[20043]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-filesystem-2.4.37-30.module_el8.3.0+561+97fdbbcc.noarch.rpm removed
	Jun 01 14:20:41 vmtest findword.sh[20043]: 2021-06-01T10:15:30Z DDEBUG /var/cache/dnf/appstream-fd636d66ef3d60cc/packages/httpd-2.4.37-30.module_el8.3.0+561+97fdbbcc.x86_64.rpm removed
	Jun 01 14:20:41 vmtest systemd[1]: findword.service: Succeeded.
	Jun 01 14:20:41 vmtest systemd[1]: Started Find word in file.


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

### 2.8 Проверяем работу сервиса spawn-fcgi.service
	[root@vmtest ~]# systemctl status spawn-fcgi.service
	● spawn-fcgi.service - Spawn-fcgi startup service by Otus
	   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
	   Active: active (running) since Tue 2021-06-01 13:15:34 MSK; 1h 8min ago
	 Main PID: 18893 (php-cgi)
		Tasks: 33 (limit: 5997)
	   Memory: 17.8M
	   CGroup: /system.slice/spawn-fcgi.service
			   ├─18893 /usr/bin/php-cgi
			   ├─18895 /usr/bin/php-cgi
			   ├─18896 /usr/bin/php-cgi
			   ├─18897 /usr/bin/php-cgi
			   ├─18898 /usr/bin/php-cgi
			   ├─18899 /usr/bin/php-cgi
			   ├─18900 /usr/bin/php-cgi
			   ├─18901 /usr/bin/php-cgi
			   ├─18902 /usr/bin/php-cgi
			   ├─18903 /usr/bin/php-cgi
			   ├─18904 /usr/bin/php-cgi
			   ├─18905 /usr/bin/php-cgi
			   ├─18906 /usr/bin/php-cgi
			   ├─18907 /usr/bin/php-cgi
			   ├─18908 /usr/bin/php-cgi
			   ├─18909 /usr/bin/php-cgi
			   ├─18910 /usr/bin/php-cgi
			   ├─18911 /usr/bin/php-cgi
			   ├─18912 /usr/bin/php-cgi
			   ├─18913 /usr/bin/php-cgi
			   ├─18914 /usr/bin/php-cgi
			   ├─18915 /usr/bin/php-cgi
			   ├─18916 /usr/bin/php-cgi
			   ├─18917 /usr/bin/php-cgi
			   ├─18918 /usr/bin/php-cgi
			   ├─18919 /usr/bin/php-cgi
			   ├─18920 /usr/bin/php-cgi
			   ├─18921 /usr/bin/php-cgi
			   ├─18922 /usr/bin/php-cgi
			   ├─18923 /usr/bin/php-cgi
			   ├─18924 /usr/bin/php-cgi
			   ├─18925 /usr/bin/php-cgi
			   └─18926 /usr/bin/php-cgi

	Jun 01 13:15:34 vmtest systemd[1]: Started Spawn-fcgi startup service by Otus.



## 3. Выполнение п.3 ДЗ

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
	
### 3.3. Копируем httpd.conf в  httpd-first.conf и httpd-second.conf. Изменяем порт простушивания и PidFile в созданных файлах.
		cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-first.conf
		cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-first.conf
		
	В файле httpd-first.conf:
		PidFile /var/run/httpd-first.pid
		Listen 8080

	В файле httpd-second.conf:
		PidFile /var/run/httpd-second.pid
		Listen 8081	

### 3.4. Перечитываем 
    systemctl daemon-reload

### 3.5. Запускаем 2 экземпляра инстенсов Apache
    systemctl start httpd@first
    systemctl start httpd@second

### 3.6. Проверяем работу запущенных экземплятор
	[root@vmtest ~]# systemctl status httpd@first.service
	● httpd@first.service - two instences Apache
	   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
	   Active: active (running) since Tue 2021-06-01 13:15:36 MSK; 1h 11min ago
	 Main PID: 18959 (httpd)
	   Status: "Running, listening on: port 8080"
		Tasks: 214 (limit: 5997)
	   Memory: 27.0M
	   CGroup: /system.slice/system-httpd.slice/httpd@first.service
			   ├─18959 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND
			   ├─18962 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND
			   ├─18963 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND
			   ├─18964 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND
			   ├─18965 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND
			   └─18966 /usr/sbin/httpd -f conf/httpd-first.conf -DFOREGROUND

	Jun 01 13:15:36 vmtest systemd[1]: Starting two instences Apache...
	Jun 01 13:15:36 vmtest httpd[18959]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.11.171. Set the 'ServerName' directive globally to suppress this message
	Jun 01 13:15:36 vmtest systemd[1]: Started two instences Apache.
	Jun 01 13:15:36 vmtest httpd[18959]: Server configured, listening on: port 8080
	
	[root@vmtest ~]# systemctl status httpd@second.service
	● httpd@second.service - two instences Apache
	   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
	   Active: active (running) since Tue 2021-06-01 13:15:36 MSK; 1h 11min ago
	 Main PID: 19101 (httpd)
	   Status: "Running, listening on: port 8081"
		Tasks: 214 (limit: 5997)
	   Memory: 26.5M
	   CGroup: /system.slice/system-httpd.slice/httpd@second.service
			   ├─19101 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND
			   ├─19180 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND
			   ├─19181 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND
			   ├─19182 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND
			   ├─19183 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND
			   └─19184 /usr/sbin/httpd -f conf/httpd-second.conf -DFOREGROUND

	Jun 01 13:15:36 vmtest systemd[1]: Starting two instences Apache...
	Jun 01 13:15:36 vmtest httpd[19101]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.11.171. Set the 'ServerName' directive globally to suppress this message
	Jun 01 13:15:36 vmtest systemd[1]: Started two instences Apache.
	Jun 01 13:15:36 vmtest httpd[19101]: Server configured, listening on: port 8081
	[root@vmtest ~]#







