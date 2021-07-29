## ДЗ к Занятию

Docker

### Задание 1

Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.

Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.

### Задание 2

Создайте кастомные образы nginx и php, 

объедините их в docker-compose.

После запуска nginx должен показывать php info.Все собранные образы должны быть в docker hub

## Решение задания 1

### 1. Устанавливаем docker

	yum install -y yum-utils
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum install -y  docker-ce docker-ce-cli containerd.io
	systemctl start docker.service
	systemctl enable docker.service

### 2. Для сборки image создаем следующие файлы.
		
    [root@vmtest docker]# ls -al
		-rwxrwxrwx. 1 vagrant vagrant  345 Jul 13 11:08 default.conf
		-rwxrwxrwx. 1 vagrant vagrant  225 Jul 23 05:02 Dockerfile
		-rwxrwxrwx. 1 vagrant vagrant  341 Jul 13 11:08 index.html

### 2.1. Содержание файла Dockerfile

		FROM alpine:3.7
		RUN apk update \
		&& apk upgrade \
		&& apk add nginx\
		&& mkdir -p /run/nginx
		COPY ./default.conf /etc/nginx/conf.d/
		COPY ./index.html /usr/share/nginx/html/
		EXPOSE 80
		CMD ["nginx", "-g", "daemon off;"]

### 2.2. Содержание файла default.conf
		
      listen       80;
			server_name  localhost;
			location / {
				root   /usr/share/nginx/html;
				index  index.html index.htm;
			}
			error_page   500 502 503 504  /50x.html;
			location = /50x.html {
				root   /usr/share/nginx/html;
			}
		}


### 2.3. Содержание файла index.html (Измененная первая страница nginx)

    <!DOCTYPE html>
		<html>
		<head>
		<title>Welcome to our personal nginx start page!</title>
		<style>
			body {
				width: 50em;
				margin: 0 auto;
				font-family: Tahoma, Verdana, Arial, sans-serif;
			}
		</style>
		</head>
		<body>
		<h1>Welcome to my docker nginx!</h1>

		<p><em>Thank you for running my docker.</em></p>
		</body>
		</html>

### 3. Собираем образ на основе файла Dockerfile.

		[root@vmtest docker]# docker build -f Dockerfile -t nginx_sa:alpine .

		Sending build context to Docker daemon  4.096kB
		Step 1/6 : FROM alpine:3.7
		 ---> 6d1ef012b567
		Step 2/6 : RUN apk update && apk upgrade && apk add nginx&& mkdir -p /run/nginx
		 ---> Running in d7dafbf94309
		fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/main/x86_64/APKINDEX.tar.gz
		fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/community/x86_64/APKINDEX.tar.gz
		v3.7.3-184-gffd32bfd09 [http://dl-cdn.alpinelinux.org/alpine/v3.7/main]
		v3.7.3-194-gcddd1b2302 [http://dl-cdn.alpinelinux.org/alpine/v3.7/community]
		OK: 9054 distinct packages available
		(1/2) Upgrading musl (1.1.18-r3 -> 1.1.18-r4)
		(2/2) Upgrading musl-utils (1.1.18-r3 -> 1.1.18-r4)
		Executing busybox-1.27.2-r11.trigger
		OK: 4 MiB in 13 packages
		(1/2) Installing pcre (8.41-r1)
		(2/2) Installing nginx (1.12.2-r4)
		Executing nginx-1.12.2-r4.pre-install
		Executing busybox-1.27.2-r11.trigger
		OK: 6 MiB in 15 packages
		Removing intermediate container d7dafbf94309
		 ---> 568d36eee844
		Step 3/6 : COPY ./default.conf /etc/nginx/conf.d/
		 ---> 6a1508ca40b8
		Step 4/6 : COPY ./index.html /usr/share/nginx/html/
		 ---> 174fde365160
		Step 5/6 : EXPOSE 80
		 ---> Running in 402bcf72763c
		Removing intermediate container 402bcf72763c
		 ---> 9a62e79444ed
		Step 6/6 : CMD ["nginx", "-g", "daemon off;"]
		 ---> Running in dc071ce0474a
		Removing intermediate container dc071ce0474a
		 ---> 51060de7681e
		Successfully built 51060de7681e
		Successfully tagged nginx_sa:alpine

Cмотрим что получилось

		[root@vmtest docker]# docker images
		REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
		nginx_sa     alpine    51060de7681e   About a minute ago   7.46MB
		alpine       3.7       6d1ef012b567   2 years ago          4.21MB

### 4. Запускаем докер с пробросом 80 порта хостовой ВМ на 80 порт докера.

		[root@vmtest docker]# docker run -d -p 80:80 nginx_sa:alpine
		959a54236a08020a84ff08709df2ab37eec4d6b6c73bf4a00cb1a5ab08a11c0a

		[root@vmtest docker]# docker ps
		CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                               NAMES
		959a54236a08   nginx_sa:alpine   "nginx -g 'daemon of…"   7 minutes ago   Up 7 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   hardcore_lovelace

Проверяем работу nginx через браузер хостовой машины подключившись по http к ВМ где запущен контейнер.

### 5. Размещение образа докера на DockerHub:

5.1. Регистрируемся на Docker Hub - aleksey10081967

5.2. Из терминала выполняем команду - docker login

5.3. После успешной авторизации указывваем образ, который хотим залить на dockerhub и его имя на портале

			docker tag nginx_sa:alpine aleksey10081967/nginx_sa-v1:alpine

***Для информации:***

***В имени образа который будет выложен на портале первым должен быть указан login созданный на портале -> aleksey10081967/nginx_sa-v1:alpine***

***Иначе при размещении на портал получаем ошибку: denied: requested access to the resource is denied***

5.4. Загружаем образ на dockerhub

			docker push aleksey10081967/nginx_sa-v1:alpine
			
Имеем загруженный на DockerHub собранный образ nginx ввиде поекта.

![picture](pic/pic1.png)

Ссылка: https://hub.docker.com/repository/docker/aleksey10081967/nginx_sa-v1:alpine

### 6. Выполняем проверку загруженного образа на портал 

	6.1 Скачиваем образ с dockerhub
	
		docker pull aleksey10081967/nginx_sa-v1:alpine
		docker images -a
			
	6.2 Запускаем контейнер
	
		docker run -d -p 80:80 aleksey10081967/nginx_sa-v1:alpine
 
 Проверяем работу nginx через браузер хостовой машины подключившись по http к ВМ где запущен контейнер.
 
 ![picture](pic/pic2.png)

## Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.

 Образ - это набор слоев,в которые в процессе создания записывается различная информация, в том числе и ПО. Данная информация статическая и ее изменение возможно при изменении  образа. А это уже новый образ.
 
Контейнер - это экземпляр образа, динамическое состояние образа. В процессе жизни контейнера в нем могут добавляться,изменяться,удалятся объекты (файлы, каталоги, ПО и т.д.), размещенные в контейнере. При уничтожении контейнера вся измененния внесенные в объекты контейнера будут потеряны. 

При повторном создании контейнера объекты будут в состояни которое сохранено в образе.

## Можно ли в контейнере собрать ядро?
Да, наверное можно. Но для запуска ядра нужно дополнительно во внутрь контейнера засунуть ПО для виртуализации. Данное ПО сможет загрузить собранное ядро.
 
