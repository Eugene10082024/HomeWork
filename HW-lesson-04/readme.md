## ДЗ к Занятию 4.
1. Отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.
2. Определение настроек pool’a
3. Найти сообщение от преподавателей


## Отработка навыков работы с созданием томов и установкой параметров. Находим наилучшее сжатие.
### 1.1. Устанавливаем репозиторий.
	[root@vm-zfa ~]# yum install http://download.zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm
	Loaded plugins: fastestmirror
	zfs-release.el7_9.noarch.rpm                                                                     | 5.4 kB  00:00:00
	Examining /var/tmp/yum-root-AL8wEu/zfs-release.el7_9.noarch.rpm: zfs-release-1-10.noarch
	Marking /var/tmp/yum-root-AL8wEu/zfs-release.el7_9.noarch.rpm to be installed

	Installed:
	  zfs-release.noarch 0:1-10
	Complete!
### 1.2. Правим репозиторий что установить zfs c kABI-tracking kmod и устанавливаем zfs

	[root@vm-zfa yum.repos.d]# vi zfs.repo
	[root@vm-zfa yum.repos.d]# yum install zfs -y
	Loaded plugins: fastestmirror
	Loading mirror speeds from cached hostfile
	 * base: mirror.logol.ru
	 * extras: mirror.docker.ru
	 * updates: mirror.docker.ru
	zfs-kmod                                                                                         | 2.9 kB  00:00:00
	zfs-kmod/x86_64/primary_db                                                                       |  82 kB  00:00:01

  zfs.x86_64 0:0.8.6-1.el7
Complete!

### 1.3. Выполняем установку драйверов zfs
	[root@vm-zfa yum.repos.d]# modprobe zfs
	
### 1.4. Проверяем
	[root@vm-zfa yum.repos.d]# lsmod | grep zfs
	zfs                  3986850  0
	zunicode              331170  1 zfs
	zlua                  151525  1 zfs
	zcommon                89551  1 zfs
	znvpair                94388  2 zfs,zcommon
	zavl                   15167  1 zfs
	icp                   301854  1 zfs
	spl                   104299  5 icp,zfs,zavl,zcommon,znvpair


### 1.5. Настраиваем загрузку драйверов при старте ОС
	[root@vm-zfs ~]# touch /etc/modules-load.d/zfs.conf
	[root@vm-zfs ~]# sudo sh -c "echo zfs >/etc/modules-load.d/zfs.conf"
	[root@vm-zfs ~]#reboot

### 1.6. Проверяем надичие драйверов после reboot.

	[root@vm-zfs ~]# lsmod | grep zfs
	zfs                  4215915  6
	zunicode              331170  1 zfs
	zzstd                 460776  1 zfs
	zlua                  151526  1 zfs
	zcommon                94235  1 zfs
	znvpair                94388  2 zfs,zcommon
	zavl                   15698  1 zfs
	icp                   301775  1 zfs
	spl                    96517  6 icp,zfs,zavl,zzstd,zcommon,znvpair


### 1.7. Имеем следущие диски на ВМ. На них будем разварачивать zfs.
	[root@vm-zfs ~]# lsblk
	NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
	sda      8:0    0  40G  0 disk
	└─sda1   8:1    0  40G  0 part /
	sdb      8:16   0  10G  0 disk
	sdc      8:32   0  10G  0 disk
	sdd      8:48   0  10G  0 disk
	sde      8:64   0  10G  0 disk
	sdf      8:80   0  10G  0 disk

### 1.8.Создаем mirror pool из sdb, sdc, sdd. Имя pool - test_pool
	[root@vm-zfs ~]# zpool create test_pool /dev/sdb /dev/sdc /dev/sdd

Смотрим что создали
	[root@vm-zfs ~]# zpool status -v
	  pool: test_pool
	 state: ONLINE
	config:

			NAME        STATE     READ WRITE CKSUM
			test_pool   ONLINE       0     0     0
			  sdb       ONLINE       0     0     0
			  sdc       ONLINE       0     0     0
			  sdd       ONLINE       0     0     0

	errors: No known data errors

### 1.9 Добавляем cache ввиде диска /dev/sde и проверям что вышло. Диск для кэша добавлен.
	[root@vm-zfs ~]# zpool add test_pool cache /dev/sde
	[root@vm-zfs ~]# zpool status -v
	  pool: test_pool
	 state: ONLINE
	config:

			NAME        STATE     READ WRITE CKSUM
			test_pool   ONLINE       0     0     0
			  sdb       ONLINE       0     0     0
			  sdc       ONLINE       0     0     0
			  sdd       ONLINE       0     0     0
			cache
			  sde       ONLINE       0     0     0

	errors: No known data errors

### 1.10 Создаем файловые системы для выполнения первого задания. Их будет 4 с различными параметрами сжатия.
	[root@vm-zfs ~]# zfs create -o compression=off test_pool/compression_off
	[root@vm-zfs ~]# zfs create -o compression=lzjb test_pool/compression_lzjb
	[root@vm-zfs ~]# zfs create -o compression=gzip test_pool/compression_gzip
	[root@vm-zfs ~]# zfs create -o compression=zle test_pool/compression_zle
	
### 1.11. смотрим что получилось.
[root@vm-zfs ~]# zfs list
	NAME                         USED  AVAIL     REFER  MOUNTPOINT
	test_pool                    296K  27.6G       29K  /test_pool
	test_pool/compression_gzip    24K  27.6G       24K  /test_pool/compression_gzip
	test_pool/compression_lzjb    24K  27.6G       24K  /test_pool/compression_lzjb
	test_pool/compression_off     24K  27.6G       24K  /test_pool/compression_off
	test_pool/compression_zle     24K  27.6G       24K  /test_pool/compression_zle

### 1.12. Скачиваем ядро Linux 5.12.3.tar.xz

	[root@vm-zfs ~]# ls -al /home/vagrant/
	total 115372
	drwx------. 3 vagrant vagrant       122 May 12 14:59 .
	drwxr-xr-x. 3 root    root           21 Apr 30  2020 ..
	-rw-------. 1 vagrant vagrant        50 May 12 14:13 .bash_history
	-rw-r--r--. 1 vagrant vagrant        18 Apr  1  2020 .bash_logout
	-rw-r--r--. 1 vagrant vagrant       193 Apr  1  2020 .bash_profile
	-rw-r--r--. 1 vagrant vagrant       231 Apr  1  2020 .bashrc
	-rwxr-xr-x. 1 root    root    118122820 May 12 14:59 linux-5.12.3.tar.xz
	drwx------. 2 vagrant vagrant        29 May 12 13:28 .ssh
	
### 1.13. Разархивируем архив в созданные файловые системы.
	[root@vm-zfs ~]# tar -xf /home/vagrant/linux-5.12.3.tar.xz  -C /test_pool/compression_off/
	[root@vm-zfs ~]# tar -xf /home/vagrant/linux-5.12.3.tar.xz  -C /test_pool/compression_gzip/
	[root@vm-zfs ~]# tar -xf /home/vagrant/linux-5.12.3.tar.xz  -C /test_pool/compression_lzjb/
	[root@vm-zfs ~]# tar -xf /home/vagrant/linux-5.12.3.tar.xz  -C /test_pool/compression_zle

### 1.14. Смотрим что получилось.
	[root@vm-zfs ~]# zfs list
	NAME                         USED  AVAIL     REFER  MOUNTPOINT
	test_pool                   2.77G  24.8G       29K  /test_pool
	test_pool/compression_gzip   262M  24.8G      262M  /test_pool/compression_gzip
	test_pool/compression_lzjb   452M  24.8G      452M  /test_pool/compression_lzjb
	test_pool/compression_off   1.08G  24.8G     1.08G  /test_pool/compression_off
	test_pool/compression_zle   1020M  24.8G     1020M  /test_pool/compression_zle

### 1.15. Вывод. 
	compression_gzip - наилучшее сжатие
	compression_lzjb
	compression_zle
	compression_off
	
## 2. Определение настроек pool’a

### 2.1. Разархивируем пул.
	[root@vm-zfs zfs_import]# tar xf zfs_task1.tar.gz

	[root@vm-zfs zfs_import]# ls -al
	total 7108
	drwxr-xr-x. 3 root    root         49 May 12 15:14 .
	drwx------. 4 vagrant vagrant     140 May 12 15:14 ..
	-rwxr-xr-x. 1 root    root    7275140 May 12 15:13 zfs_task1.tar.gz
	drwxr-xr-x. 2 root    root         32 May 15  2020 zpoolexport

### 2.2. Смотрим свойства скаченного пула
		[root@vm-zfs zfs_import]# zpool import -d /home/vagrant/zfs_import/zpoolexport/
	   pool: otus
		 id: 6554193320433390805
	  state: ONLINE
	status: Some supported features are not enabled on the pool.
	 action: The pool can be imported using its name or numeric identifier, though
			some features will not be available without an explicit 'zpool upgrade'.
	 config:

			otus                                            ONLINE
			  mirror-0                                      ONLINE
				/home/vagrant/zfs_import/zpoolexport/filea  ONLINE
				/home/vagrant/zfs_import/zpoolexport/fileb  ONLINE
### 2.3. Имортируем пул otus 
	[root@vm-zfs zfs_import]# zpool import otus -d /home/vagrant/zfs_import/zpoolexport/

			
### 2.4. Выводим информацию по импортированному пулу.			
	[root@vm-zfs zfs_import]# zpool list
	NAME        SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
	otus        480M  2.21M   478M        -         -     0%     0%  1.00x    ONLINE  -
	test_pool  28.5G  2.77G  25.7G        -         -     0%     9%  1.00x    ONLINE  -		

### 2.5. Выподим детальную информацию по импортированному пулу
	[root@vm-zfs zfs_import]# zpool get all zpoolexport
	[root@vm-zfs zfs_import]# zpool get all otus
	NAME  PROPERTY                       VALUE                          SOURCE
	otus  size                           480M                           -
	otus  capacity                       0%                             -
	otus  altroot                        -                              default
	otus  health                         ONLINE                         -
	otus  guid                           6554193320433390805            -
	otus  version                        -                              default
	otus  bootfs                         -                              default
	otus  delegation                     on                             default
	otus  autoreplace                    off                            default
	otus  cachefile                      -                              default
	otus  failmode                       wait                           default
	otus  listsnapshots                  off                            default
	otus  autoexpand                     off                            default
	otus  dedupratio                     1.00x                          -
	otus  free                           478M                           -
	otus  allocated                      2.09M                          -
	otus  readonly                       off                            -
	otus  ashift                         0                              default
	otus  comment                        -                              default
	otus  expandsize                     -                              -
	otus  freeing                        0                              -
	otus  fragmentation                  0%                             -
	otus  leaked                         0                              -
	otus  multihost                      off                            default
	otus  checkpoint                     -                              -
	otus  load_guid                      7482141103932361557            -
	otus  autotrim                       off                            default
	otus  feature@async_destroy          enabled                        local
	otus  feature@empty_bpobj            active                         local
	otus  feature@lz4_compress           active                         local
	otus  feature@multi_vdev_crash_dump  enabled                        local
	otus  feature@spacemap_histogram     active                         local
	otus  feature@enabled_txg            active                         local
	otus  feature@hole_birth             active                         local
	otus  feature@extensible_dataset     active                         local
	otus  feature@embedded_data          active                         local
	otus  feature@bookmarks              enabled                        local
	otus  feature@filesystem_limits      enabled                        local
	otus  feature@large_blocks           enabled                        local
	otus  feature@large_dnode            enabled                        local
	otus  feature@sha512                 enabled                        local
	otus  feature@skein                  enabled                        local
	otus  feature@edonr                  enabled                        local
	otus  feature@userobj_accounting     active                         local
	otus  feature@encryption             enabled                        local
	otus  feature@project_quota          active                         local
	otus  feature@device_removal         enabled                        local
	otus  feature@obsolete_counts        enabled                        local
	otus  feature@zpool_checkpoint       enabled                        local
	otus  feature@spacemap_v2            active                         local
	otus  feature@allocation_classes     enabled                        local
	otus  feature@resilver_defer         enabled                        local
	otus  feature@bookmark_v2            enabled                        local
	otus  feature@redaction_bookmarks    disabled                       local
	otus  feature@redacted_datasets      disabled                       local
	otus  feature@bookmark_written       disabled                       local
	otus  feature@log_spacemap           disabled                       local
	otus  feature@livelist               disabled                       local
	otus  feature@device_rebuild         disabled                       local
	otus  feature@zstd_compress          disabled                       local
	
	[root@vm-zfs zfs_import]# df -h
	Filesystem                  Size  Used Avail Use% Mounted on
	devtmpfs                    110M     0  110M   0% /dev
	tmpfs                       118M     0  118M   0% /dev/shm
	tmpfs                       118M  4.6M  113M   4% /run
	tmpfs                       118M     0  118M   0% /sys/fs/cgroup
	/dev/sda1                    40G  5.0G   36G  13% /
	tmpfs                        24M     0   24M   0% /run/user/1000
	test_pool                    25G  128K   25G   1% /test_pool
	test_pool/compression_off    26G  1.1G   25G   5% /test_pool/compression_off
	test_pool/compression_lzjb   26G  453M   25G   2% /test_pool/compression_lzjb
	test_pool/compression_gzip   26G  262M   25G   2% /test_pool/compression_gzip
	test_pool/compression_zle    26G 1020M   25G   4% /test_pool/compression_zle
	//10.60.32.55/10-dir_Linux  477G  185G  292G  39% /mnt/windows
	otus                        350M  128K  350M   1% /otus
	otus/hometask2              352M  2.0M  350M   1% /otus/hometask2
	
### 2.6. Выводим информацию обо всех файловых систем.
	[root@vm-zfs zfs_import]# zfs get -s local all
	NAME                        PROPERTY              VALUE                        SOURCE
	otus                        recordsize            128K                         local
	otus                        checksum              sha256                       local
	otus                        compression           zle                          local
	test_pool/compression_gzip  compression           gzip                         local
	test_pool/compression_lzjb  compression           lzjb                         local
	test_pool/compression_off   compression           off                          local
	test_pool/compression_zle   compression           zle                          local


## 3. Поиск сообщение от преподавателей 

### 3.1. Скачиваем файл из Инета 
	https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 

### 3.2. Восстанавливаем данные из snapshot
	less otus_task2.file | zfs receive -F test_pool/compression_off
	и
	zfs receive -d -F test_pool/compression_lzjb < otus_task2.file

### 3.3. Ищем файл и выводим его содержимое

	[root@vm-zfs secret]# find / -name 'secret_message'
		/test_pool/compression_off/task1/file_mess/secret_message
		/test_pool/compression_lzjb/storage/task1/file_mess/secret_message
		
Содержимое:
	https://github.com/sindresorhus/awesome
	
