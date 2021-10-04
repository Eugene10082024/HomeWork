### ДЗ к Занятию 34
LDAP
Задания:
	1. Установить FreeIPA;
	2. Написать Ansible playbook для конфигурации клиента
	3. Настроить аутентификацию по SSH-ключам
	4. Firewall должен быть включен на сервере и на клиенте
	
### Решение заданий.
Выполнение п.3 и п.4 осуществляется в процессе развертывания контроллера домена (включение и настройка firewalld) и включения клиентов в домен (включение и настройка firewalld, авторизация по ssh ключам)

#### Для установки и настройки сервера и клиентов FreeIPA были опередены:

	Имя домена  - ipatest.local
	Имя сервера - ipaserver.ipatest.local
	IP сервера  - 192.168.11.240
	IP DNS 	    - 192.168.11.240
	
FreeIPA клиенты:
    - для vagrant файла:
		Имя клиента - ipaclient
		IP клиента  - 192.168.11.241
	- для ansible:
	        Имя клиента - ipaclient01
		IP  клиента - 192.168.11.242
			
#### Развертывание домена FreeIPA с помощью vagrant 			

Развертывание домена выполняется с помощью файла vagrantfile_freeipa.
	
	Переименуйте файл Vagrantfile_freeipa -> Vagrantfile
	Выполните -> vagrant up 
	
По завершению работы vagrant, будут подняты:
	1. контроллер домена FreeIPA (ipaserver)
	2. Клиентское рабочее место введенное в домен FreeIPA (ipaclient)
	3. Поднят web интерфейс упраления домена. 
	4. Создана учетная запись admin для управления доменом

Для того чтобы получить доступ через web интерфейс к управлению контроллером домена необходимо в файл hosts хостовой машины добавить следующую строку:

	192.168.11.240	 ipaserver.ipatest.local
	
После чего в браузере ввести - https://ipaserver.ipatest.local 

пользователь: admin  
пароль: 12345678

#### Подключение клиента через playbook Ansible.

Создание  клиентов выполняется с помощью vagrant файла - vagrantfile_client 
	
	Переименуйте файл Vagrantfile_client -> Vagrantfile 
	
	Выполните -> vagrant up 

По окончании работы vagrant будет развернут ipaclient01. 

Для ввода в домен необходимо использовать playbook: ansible-playbook ipaclient.yml

Перед запуском playbook  необходимо заполнить следующие файлы:

##### provisioning/inventories/hosts
	
 	[clients]
	ipaclient01   ansible_host=192.168.11.242   ansible_user=ansible ansible_password=ansible ansible_become=yes ansible_become_password=ansible
	
	
##### provisioning/inventories/group_vars/clients.yml - файл в котором определены переменные для группы clients
	
	domain_ipa_fqdn: ipatest.local
	realm_ipa: IPATEST.LOCAL
	server_ipa: ipaserver.ipatest.local
	admin_user: admin
	password_admin: 12345678
	dns_ipa_server_ip: 192.168.11.240
	dns_dop: 10.0.2.3

	
	где - domain_ipa_fqdn 	    - имя домена FreeIPA
		  realm_ipa	    - realm домена 
		  server_ipa 	    - FQDN развернутого контроллера домена FreeIPA	
	      admin_user      	    - администратор домена
		  password_admin    - пароль администратора
		  dns_ipa_server_ip - DNS который будет использоваться в домене FreeIPA
		  dns_dop 	    - дополнительный dns который используется для разрешения внешних имен.
		  
		  
	
##### provisioning/inventories/host_vars/ipaclient01.yml - файл в котором определены переменные для конкретного клиента
Такой файл создается для каждого клиента которого Вы хотите ввести в домен.
	
	ip_client_ipa: 192.168.11.241
	fqdn_client_ipa: ipaclient01.ipatest.local
	name_client_ipa: ipaclient01

	где - 	ip_client_ipa   - IP клиента
		fqdn_client_ipa - FQDN клиента
		name_client_ipa	- имя клиента 		
	

##### Выполнение playbook ipaclient.yml

Вариант 1. В файле vagrantfile_client разкомментитровать следующие строки:

		config.vm.provision "ansible" do |ansible|
			ansible.verbose = "vvv"
			ansible.playbook = "provisioning/ipaclient.yml"
			ansible.become = "true"
		end
После чего выполнить команду:
		
		vagrant provision
		
Вариант 2. Использовать отдельную ВМ для запуска playbook ansible.

Для этого:
		1. все содершимое каталога provisioning перенести на данную BM в каталог /etc/ansible
		2. создать пользователя ansible c правами sudo
		3. сгенерировать ssh ключ командой ssh-keygen и перенести публичный ключ на клиентов которые необходимо ввести в домен freeipa командой ssh-copy-id 
		4. Выполнить проверку доступности клиентов:  ansible -m ping all
		5. Если все хосты доступны выполнить:ansible-playbook ipaclient.yml
		
#### Проверка наличия клиента в домене.
Проверку выполняем путем подключения по web интерфейсу к контроллеру домена freeipa и просмотра наличия узла ipaclient01.ipatest.local во вкладке узлы.
![picture](pic/pic_1.png)

![picture](pic/pic_2.png)







 
