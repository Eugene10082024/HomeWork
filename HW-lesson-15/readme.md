## ДЗ к Занятию 15
PAM

1. Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

2. Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис

### Пывыполнение настроек.
1. Устанавливаем дополнительные пакеты (Docker). 
	
2. Включаем пользователя vagrant в группу docker, дредоставления возможности управления докерами.

3. Созданием группу admin	

4. Создаем 3-х пользователей	
		
5. Присваиваем созданным пользователям пароль 	

6. Создаем записи в файле /etc/security/time.conf для запрещения login пользователей user01 и user02 в выходные дни 

		*;*;admin01;Al0000-2400
		*;*;user01;!SuSa0000-2400
		*;*;user02;SuSa0000-2400
		
7. Добавляем строку в pam файл /etc/pam.d/sshd : account     required       pam_time.so
		
8. Добавляем пользователя admin01 в группу admin
	
9. Копируем скрипт проверяющий права доступа (группа и дни недели) на ВМ
	
		Содержание скрипта pam-rule-gr-admin.sh:
			#!/bin/bash
			NUM_DAY=$(date '+%u')
			AMIN_GROUP=$(groups $PAM_USER | grep -c admin)
			if [[ $ADMIN_GROUP -eq 1 ]] ; then
				exit 0
			else
				if [[ $NUM_DAY -gt 5 ]] ; then 
					exit 1
				else
					exit 0
				fi	
			fi

10. Добавляем закомментированную строку опредеяющую проверку доступа с помощью скрипта: 

		#account     required       pam_exec.so /usr/local/bin/pam-rule-gr-admin.sh

11. Копируем файл с rule предоставляющим возможность запуска, перезапуска и останова сервиса docker пользователю vagrant.

Содержание скрипта 01-systemctl.rules:

        	polkit.addRule(function(action, subject) {
			if (action.id.match("org.freedesktop.systemd1.manage-units") && subject.user=== "vagrant")
			{
					return polkit.Result.YES;
			}
			})

Все команды можно посмотреть в файле vagrantfile.

### Выполнение развертывание ВМ

Скопировать каталог с github на лакальный ПК

Выполнить команду:

	vagrant up
	
После развертывния ВМ выполнить проверки.

### Проверка ограничения доступа по ssh  пользователей по времени (PAM - pam_time.so).

Выполняем удаленное подключение по ssh к ВМ:

	ssh admin01@192.168.11.195 
	ssh	user01@192.168.11.195
	
	Пароль для подключения в (12345678)

Ожидаемые результаты:

	user01 - отказано в подключении по ssh в выходные дни

	admin01 - успешно подключается к ПК в выходные дни

### Проверка ограничения доступа по ssh пользователей в зависимости от включения в группу admin и дня недели (PAM - pam_exec.so)

Для выполнения данной проверки необходимо в файле /etc/pam.d/sshd:

закомментировать строку:

		account     required       pam_time.so

раскомментировать строку:

		#account     required       pam_exec.so /usr/local/bin/pam-rule-gr-admin.sh		

После чего удаленно подключиться по ssh под следующими пользователями:

	ssh admin01@192.168.11.195 
	ssh	user01@192.168.11.195
	
	Пароль для подключения в (12345678)

Ожидаемые результаты:

	user01 - отказано в подключении по ssh в выходные дни т.к. user01 не является членом группы admin


### Проверка возможности сервиса docker под пользователем vagrant

Запускаем сервис docker под учетной записью vagrant

		[vagrant@vmtest ~]$ systemctl start docker

Выполняем проверку статуса сервиса docker

		[vagrant@vmtest ~]$ systemctl status docker
		● docker.service - Docker Application Container Engine
   		Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
   		Active: active (running) since Fri 2021-07-02 13:54:35 UTC; 7s ago
			 Docs: https://docs.docker.com
		 Main PID: 16021 (dockerd)
			Tasks: 8
		   Memory: 45.1M
		   CGroup: /system.slice/docker.service
				   └─16021 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
				
Останавливаем сервис docker под учетной записью vagrant

		[vagrant@vmtest ~]$ systemctl stop docker
		Warning: Stopping docker.service, but it can still be activated by:
  		docker.socket

Проверяем статус сервиса docker

		[vagrant@vmtest ~]$ systemctl status docker
		● docker.service - Docker Application Container Engine
   		Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
   		Active: inactive (dead) since Fri 2021-07-02 14:06:58 UTC; 11s ago
     		Docs: https://docs.docker.com
  		Process: 16021 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock (code=exited, status=0/SUCCESS)
 		Main PID: 16021 (code=exited, status=0/SUCCESS)
