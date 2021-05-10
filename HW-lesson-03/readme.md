## ДЗ к Занятию 3.
## Работа с lvm - что сделать.

1. Уменьшить том под / до 8G 

2. выделить том под /home выделить том под /var /var - сделать в mirror /home - сделать том для снэпшотов прописать монтирование в fstab попробовать с разными опциями и разными файловыми системами ( на выбор). Cгенерить файлы в /home/, снять снэпшот, удалить часть файлов, восстановится со снэпшота
    
3. На нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

Для выполнения ДЗ был скачен файл vagrantfile c https://gitlab.com/otus_linux/stands-03-lvm.git. Выполнено развертывание ВМ и вход.

    vagrant up
    
    vagrant ssh

## Выполнение п.1

 1.1. Выполняем lsblk
 
        [vagrant@localhost ~]$ lsblk
        NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT

        sda                       8:0    0   40G  0 disk 

        ├─sda1                    8:1    0    1M  0 part 

        ├─sda2                    8:2    0    1G  0 part /boot

        └─sda3                    8:3    0   39G  0 part 

        ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
        
        └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
        
        sdb                       8:16   0   10G  0 disk 

        sdc                       8:32   0    2G  0 disk 

        sdd                       8:48   0    1G  0 disk 

        sde                       8:64   0    1G  0 disk 
     
/dev/sdb - буду использовать как временный том для раздела /

Под раздел /home выделю место на VolGroup00 в размере 2GB, после выполнения уменьшения логического тома / 

/dev/sdd и /dev/sde - буду использовать для создания mirror тома и переноса /var

        
1.2. смотрим какая файловая система установлена в LVM разделе /.
    less /etc/fstab
    
    UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0


Установлена xfs. Для работы с ней дополнительно устанавливаем пакет     xfsdump

    yum install xfsdump

    Installed:
    
    xfsdump.x86_64 0:3.1.7-1.el7                                                                                                                                                                                                             

    Dependency Installed:
    
    attr.x86_64 0:2.4.46-13.el7 

1.3. Создаем веременный том для переноса /

    [root@localhost ~]# pvcreate /dev/sdb
    
    Physical volume "/dev/sdb" successfully created.
    
    [root@localhost ~]# vgcreate vg_migrate /dev/sdb
    
    Volume group "vg_migrate" successfully created
    
    [root@localhost ~]# lvcreate -n lv_migrate -l +100%FREE /dev/vg_migrate
    
    Logical volume "lv_migrate" created.
    
1.4. Создаем на созданном томе ФС.

    root@localhost ~]# mkfs.xfs /dev/vg_migrate/lv_migrate
    
    meta-data=/dev/vg_migrate/lv_migrate isize=512    agcount=4, agsize=655104 blks
    
             =                       sectsz=512   attr=2, projid32bit=1
             
             =                       crc=1        finobt=0, sparse=0
             
    data     =                       bsize=4096   blocks=2620416, imaxpct=25
    
             =                       sunit=0      swidth=0 blks
             
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
    
    log      =internal log           bsize=4096   blocks=2560, version=2
    
             =                       sectsz=512   sunit=0 blks, lazy-count=1
             
    realtime =none                   extsz=4096   blocks=0, rtextents=0
 
  1.5. Монтируем LVM раздел на /mnt и проверяем
 
    mount /dev/vg_migrate/lv_migrate /mnt
        
    [root@localhost ~]# df -h
    
    Filesystem                         Size  Used Avail Use% Mounted on
    
    /dev/mapper/VolGroup00-LogVol00     38G  766M   37G   2% /
    
    devtmpfs                           109M     0  109M   0% /dev
    
    tmpfs                              118M     0  118M   0% /dev/shm
    
    tmpfs                              118M  4.5M  114M   4% /run
    
    tmpfs                              118M     0  118M   0% /sys/fs/cgroup
    
    /dev/sda2                         1014M   63M  952M   7% /boot
    
    tmpfs                               24M     0   24M   0% /run/user/1000
    
    /dev/mapper/vg_migrate-lv_migrate   10G   33M   10G   1% /mnt
        
1.6. Копируем данные из раздела / в раздел /mnt

    xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
    
    xfsrestore: Restore Status: SUCCESS
    
1.7. Переконфигурируем grub для того, чтобы при старте перейти в новый / (/mnt)

    [root@localhost ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
    
    [root@localhost ~]# chroot /mnt/
    
    [root@localhost /]# grub2-mkconfig -o /boot/grub2/grub.cfg
    
    Generating grub configuration file ...
    
    Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
    
    Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
    
    done
    
1.8. Обновим образ initrd.

    [root@localhost /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

    Creating image file
    
    Creating image file done
    
    Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done
    
1.9. Чтобы при загрузке был смонтирован нужный root: в файле /boot/grub2/grub.cfg заменим rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root.

    vi /etc/default/grub

        GRUB_TIMEOUT=1
        
        GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
        
        GRUB_DEFAULT=saved
        
        GRUB_DISABLE_SUBMENU=true
        
        GRUB_TERMINAL_OUTPUT="console"
        
        GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=vg_migrate/lv_migrate rd.lvm.lv=vg_migrate/lv_migrate rhgb quiet"
        
        GRUB_DISABLE_RECOVERY="true"

1.10. Еще раз обновляем grub, выходим из режима chroot (Ctrl-D) и выполняем reboot

    [root@localhost boot]# grub2-mkconfig -o /boot/grub2/grub.cfg
    
        Generating grub configuration file ...
        
        Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
        
        Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
        
        done

1.11. После загрузки ВМ выполняем df -h и lsblk

    [vagrant@localhost ~]$ df -h
        
            Filesystem                         Size  Used Avail Use% Mounted on
            
            /dev/mapper/vg_migrate-lv_migrate   10G  765M  9.3G   8% /
            
            devtmpfs                           110M     0  110M   0% /dev
            
            tmpfs                              118M     0  118M   0% /dev/shm
            
            tmpfs                              118M  4.5M  114M   4% /run
            
            tmpfs                              118M     0  118M   0% /sys/fs/cgroup
            
            /dev/sda2                         1014M   61M  954M   6% /boot
            
            tmpfs                               24M     0   24M   0% /run/user/1000


    [vagrant@localhost ~]$ lsblk
    
        NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
        
        sda                       8:0    0   40G  0 disk 
        
        ├─sda1                    8:1    0    1M  0 part 
        
        ├─sda2                    8:2    0    1G  0 part /boot
        
        └─sda3                    8:3    0   39G  0 part 
        
        ├─VolGroup00-LogVol00 253:1    0 37.5G  0 lvm  
        
        └─VolGroup00-LogVol01 253:2    0  1.5G  0 lvm  [SWAP]
        
        sdb                       8:16   0   10G  0 disk 
        
        └─vg_migrate-lv_migrate 253:0    0   10G  0 lvm  /
        
        sdc                       8:32   0    2G  0 disk 
        
        sdd                       8:48   0    1G  0 disk 
        
        sde                       8:64   0    1G  0 disk 
    
1.12 Удаляем  LogVol00, создаем LogVol00 размером 8 GB, возвращаем на него root выполним п.1.4. - 1.10,заменяя vg_migrate/lv_migrate на VolGroup00/LogVol00:

    lvremove /dev/VolGroup00/LogVol00
        
    [root@localhost ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
    
        WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
        
        Wiping xfs signature on /dev/VolGroup00/LogVol00.
        
        Logical volume "LogVol00" created.

1.13, Ниже приведена последовательность команд без вывода (п.1.4. - 1.10.):

    mount /dev/VolGroup00/LogVol00 /mnt
    
    xfsdump -J - /dev/vg_migrate/lv_migrate | xfsrestore -J - /mnt    
    
    for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
    
    chroot /mnt/
    
    grub2-mkconfig -o /boot/grub2/grub.cfg
    
    cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
    
    vi /etc/default/grub -> заменяем vg_migrate/lv_migrate на VolGroup00/LogVol00    
    
    grub2-mkconfig -o /boot/grub2/grub.cfg
    
    Ctrl-D
    
    reboot
    
1.14 Проверяем что получилось.

    [vagrant@localhost ~]$ lsblk
        NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
        
        sda                       8:0    0   40G  0 disk 
        
        ├─sda1                    8:1    0    1M  0 part 
        
        ├─sda2                    8:2    0    1G  0 part /boot
        
        └─sda3                    8:3    0   39G  0 part 
        
        ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
        
        └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
        
        sdb                       8:16   0   10G  0 disk 
        
        └─vg_migrate-lv_migrate 253:2    0   10G  0 lvm  
        
        sdc                       8:32   0    2G  0 disk 
        
        sdd                       8:48   0    1G  0 disk 
        
        sde                       8:64   0    1G  0 disk 
    
    [vagrant@localhost ~]$ df -h
        Filesystem                       Size  Used Avail Use% Mounted on
        
        /dev/mapper/VolGroup00-LogVol00  8.0G  765M  7.3G  10% /
        
        devtmpfs                         110M     0  110M   0% /dev
        
        tmpfs                            118M     0  118M   0% /dev/shm
        
        tmpfs                            118M  4.5M  114M   4% /run
        
        tmpfs                            118M     0  118M   0% /sys/fs/cgroup
        
        /dev/sda2                       1014M   61M  954M   6% /boot
        
        tmpfs                             24M     0   24M   0% /run/user/1000
        
1.15 Удаляем временный LVM том созданный для переноса /
        
        lvremove /dev/vg_migrate/lv_migrate
        
        vgremove /dev/vg_migrate
        
        pvremove /dev/sdb

## Выполнение п.2

### 2.1. Переносим  /var на созданное зеркало LVM (/dev/sdd и /dev/sde):

2.1.1 Создаем зерколо LVM

        pvcreate /dev/sdd /dev/sde

        vgcreate vg_var /dev/sdd /dev/sde

        lvcreate -L 950M -m1 -n lv_var vg_var

2.1.2. Создаем на нем ФС 

        mkfs.xfs /dev/vg_var/lv_var

2.1.3. Монтируем созданный LVM раздел к /mnt

        mount /dev/vg_var/lv_var /mnt
        
2.1.4. перемещаем в /mnt данные из /var:

        cp -aR /var/* /mnt/      

2.1.5. Монтируем новый var в каталог /var:

        umount /mnt
        
2.1.6. проверяем как примонтировался LVM раздел к /var         
    [root@localhost ~]# df -h
    
        Filesystem                       Size  Used Avail Use% Mounted on
        
        /dev/mapper/VolGroup00-LogVol00  8.0G  765M  7.3G  10% /
        
        devtmpfs                         110M     0  110M   0% /dev
        
        tmpfs                            118M     0  118M   0% /dev/shm
        
        tmpfs                            118M  4.6M  114M   4% /run
        
        tmpfs                            118M     0  118M   0% /sys/fs/cgroup
        
        /dev/sda2                       1014M   61M  954M   6% /boot
        
        /dev/mapper/vg_var-lv_var        949M  173M  776M  19% /var
        
        tmpfs                             24M     0   24M   0% /run/user/1000

2.1.7. Правим fstab для автоматического монтирования /var:

Для этого используем UUID LVM раздела:
    
    /dev/mapper/vg_var-lv_var: UUID="7aa6a53b-ec63-4933-89e0-cc6f97a220ca" TYPE="xfs"        

    [root@localhost ~]# cat /etc/fstab
    
        /dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
        
        UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
        
        /dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0

        UUID=7aa6a53b-ec63-4933-89e0-cc6f97a220ca  /var         xfs     defaults        0 0

2.1.8. Перегружаем ВМ и проверяем что вышло.

    [vagrant@localhost ~]$ df -h
    
    Filesystem                       Size  Used Avail Use% Mounted on
    
    /dev/mapper/VolGroup00-LogVol00  8.0G  765M  7.3G  10% /
    
    devtmpfs                         110M     0  110M   0% /dev
    
    tmpfs                            118M     0  118M   0% /dev/shm
    
    tmpfs                            118M  4.6M  114M   4% /run
    
    tmpfs                            118M     0  118M   0% /sys/fs/cgroup
    
    /dev/sda2                       1014M   61M  954M   6% /boot
    
    /dev/mapper/vg_var-lv_var        949M  175M  775M  19% /var
    
    tmpfs                             24M     0   24M   0% /run/user/1000

### 2.2. Работа с разделом /home

2.2.1 Создаем логический том размером в 2GB на  на VolGroup00

    lvcreate -n lv_home -L 2G /dev/VolGroup00 

    [root@localhost ~]# lvscan
    
    ACTIVE            '/dev/VolGroup00/LogVol01' [1.50 GiB] inherit
    
    ACTIVE            '/dev/VolGroup00/LogVol00' [8.00 GiB] inherit
    
    ACTIVE            '/dev/VolGroup00/lv_home' [2.00 GiB] inherit
    
    ACTIVE            '/dev/vg_var/lv_var' [952.00 MiB] inherit

2,2.2 Форматируем созданный том: 

    mkfs.xfs /dev/VolGroup00/lv_home
    
2.2.3. Монтируем том к /mnt    

        mount /dev/VolGroup00/lv_home /mnt/

2.2.4. Копируем данные:

        cp -aR /home/* /mnt/

2.2.5. Отмонтируем том от /mnt        
        
        umount /mnt
        
2.2.6 Удаляем из каталога /home все что там было

       rm -rf /home/* 

2.2.7 монтируем том LVM к /home

        mount /dev/VolGroup00/lv_home /home/

2.2.8. Правим fstab для автоматического монтирования /home

    /dev/mapper/VolGroup00-lv_home: UUID="dfeaa9b4-1259-43d2-9f7c-4256a5bda8a8" TYPE="xfs" 
      
    cat /etc/fstab
    
        /dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
        
        UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
        
        /dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
        
        UUID=7aa6a53b-ec63-4933-89e0-cc6f97a220ca  /var         xfs     defaults        0 0
        
        UUID=dfeaa9b4-1259-43d2-9f7c-4256a5bda8a8  /home        xfs     defaults        0 0

2.2.9. Проверяем правильность записей в файле /etc/fstab и перегружаем ВМ
        
        mount -a
        
        reboot

2.2.10. Сгенерируем файлы в /home/:

        mkdir /home/files
        
        touch /home/files/test{1..100}
        
        mkdir /home/files_02
        
        touch /home/files_02/test{1..200}

2.2.11. Создадим снапшот:

        lvcreate -L 50MB -s -n home_snap /dev/VolGroup00/lv_home

2.2.12. Удаляем каталог /home/files_02 со всем содержимым:

        rm -rf /home/files_02
        
        [root@localhost home]# ls -al
        total 4
        
        drwxr-xr-x.  4 root    root      34 May  8 17:45 .
        
        drwxr-xr-x. 17 root    root     224 May  8 16:08 ..
        
        drwxr-xr-x.  2 root    root    4096 May  8 17:40 files
        
        drwx------.  3 vagrant vagrant   95 May  8 14:12 vagrant


2.2.13. Восстанавливаем данные из снапшота:

        lvconvert --merge /dev/VolGroup00/home_snap
        
        mount /home

        reboot

## Выполнение п.3

Работы по данному пункту я проводит на чистой ВМ т.к. случайно снес плоды предыдущей работы. Сломал ВМ.

Т.к. с zfs не работал использовал следующие материалы 

    https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL%20and%20CentOS.html#testing-repositories

    https://www.symmcom.com/docs/how-tos/storages/how-to-install-zfs-on-centos-7

    https://blog.denisbondar.com/post/zfs-manual-rus

    https://docs.oracle.com/cd/E19253-01/820-0836/index.html

3.1. Проверяем версию CentOS
    
    [root@localhost ~]# uname -r
    
    3.10.0-1160.25.1.el7.x86_64

    [root@localhost ~]# cat /etc/redhat-release 
    
    CentOS Linux release 7.9.2009 (Core)


3.2. Устанавливаем репозиторий zfs для версии centOS 7.9

   yum install http://download.zfsonlinux.org/epel/zfs-release.el7_9.noarch.rpm

    Running transaction
    Installing : zfs-release-1-10.noarch                                                                                                                                                                                               1/1 
    Verifying  : zfs-release-1-10.noarch                                                                                                                                                                                                 1/1 

    Installed:
    zfs-release.noarch 0:1-10   
    
3.3. Вносим изменения в файл /etc/yum.repos.d/zfs.repo

БЫЛО:

    [zfs]
    
    name=OpenZFS for EL7 - dkms
    
    baseurl=http://download.zfsonlinux.org/epel/7.9/$basearch/
    
    enabled=1
    
    metadata_expire=7d
    
    gpgcheck=1
    
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

    
    
    [zfs-kmod]
    
    name=OpenZFS for EL7 - kmod
    
    baseurl=http://download.zfsonlinux.org/epel/7.9/kmod/$basearch/
    
    enabled=0
    
    metadata_expire=7d
    
    gpgcheck=1
    
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

Меняем в раздлеле zfs enabled на 0, а в разделе zfs-kmod enabled на 1 и имеем

СТАЛО:

    [zfs]
    
    name=OpenZFS for EL7 - dkms
    
    baseurl=http://download.zfsonlinux.org/epel/7.9/$basearch/
    
    enabled=0
    
    metadata_expire=7d
    
    gpgcheck=1
    
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

    [zfs-kmod]
    
    name=OpenZFS for EL7 - kmod
    
    baseurl=http://download.zfsonlinux.org/epel/7.9/kmod/$basearch/
    
    enabled=1
    
    metadata_expire=7d
    
    gpgcheck=1
    
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

3.3.   Выполняем установку пакетов zfs И reboot ВМ
        yum install zfs -y

        Installed:
        
        zfs.x86_64 0:0.8.6-1.el7                                                                                                                                                                                                                 

        Dependency Installed:
        
        kmod-zfs.x86_64 0:0.8.6-1.el7      libnvpair1.x86_64 0:0.8.6-1.el7     libuutil1.x86_64 0:0.8.6-1.el7     libzfs2.x86_64 0:0.8.6-1.el7     libzpool2.x86_64 0:0.8.6-1.el7     
        
        lm_sensors-libs.x86_64 0:3.4.0-8.20160601gitf9185e5.el7    
        
        sysstat.x86_64 0:10.1.5-19.el7    
    
        Complete!

3.4. После перезагрузки проверяем правильность установки модулей zfs. Должны быть загруженные модули zfs.
    lsmod | grep zfs
    
вывод пустой. 

3.5. Проводим анализ /var/log/messages
Имеем:
    May 10 11:55:53 localhost yum[1247]: Installed: zfs-release-1-4.el7_3.centos.noarch
    
    May 10 12:02:09 localhost yum[1283]: Updated: zfs-release-1-10.noarch
    
    May 10 12:09:53 localhost yum[1330]: Installed: libzfs2-0.8.6-1.el7.x86_64
    
    May 10 12:10:22 localhost yum[1330]: Installed: kmod-zfs-0.8.6-1.el7.x86_64
    
    May 10 12:10:23 localhost yum[1330]: Installed: zfs-0.8.6-1.el7.x86_64
    
    May 10 12:12:07 localhost zed: Failed to initialize libzfs
    
    May 10 12:12:07 localhost systemd: zfs-zed.service: main process exited, code=exited, status=1/FAILURE
    
    May 10 12:12:07 localhost systemd: Unit zfs-zed.service entered failed state.
    
    May 10 12:12:07 localhost systemd: zfs-zed.service failed.
    
    May 10 12:12:07 localhost zfs: The ZFS modules are not loaded.
    
 Не инициализируется библиотека  libzfs.

3.6. переходим на https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL%20and%20CentOS.html#testing-repositories в выполняем рекомендации по установке zfs

В частности выполняю рекомендании касающиеся CentOS 7.9 и kABI-tracking kmod. Дополнительно устанавиливсаем пакет zfs-testing-kmod для kABI-tracking kmod.

    grep xfs /var/log/mesages - что сделал yum.
    
    May 10 12:35:08 localhost yum[1399]: Installed: libzfs4-2.0.4-1.el7.x86_64
    
    May 10 12:35:41 localhost yum[1399]: Updated: kmod-zfs-2.0.4-1.el7.x86_64
    
    May 10 12:35:41 localhost yum[1399]: Updated: zfs-2.0.4-1.el7.x86_64
    
    May 10 12:36:00 localhost yum[1399]: Erased: libzfs2-0.8.6-1.el7.x86_64


3.7. После установки перегружаю ВМ и проверяю наличие активных модулей zfs и службы zfs-share.service и zfs-zed.service.

    lsmod | grep zfs
    zfs                  4215915  6 
    
    zunicode              331170  1 zfs
    
    zzstd                 460776  1 zfs
    
    zlua                  151526  1 zfs
    
    zcommon                94235  1 zfs
    
    znvpair                94388  2 zfs,zcommon
    
    zavl                   15698  1 zfs
    
    icp                   301775  1 zfs
    
    spl                    96517  6 icp,zfs,zavl,zzstd,zcommon,znvpair
 
 
    [root@localhost log]# systemctl status zfs-zed.service
    
    ● zfs-zed.service - ZFS Event Daemon (zed)
    
    Loaded: loaded (/usr/lib/systemd/system/zfs-zed.service; enabled; vendor preset: enabled)
    
    Active: active (running) since Mon 2021-05-10 12:36:29 UTC; 15min ago
    

    [root@localhost log]# systemctl status zfs-share.service
    
    ● zfs-share.service - ZFS file system shares
    
    Loaded: loaded (/usr/lib/systemd/system/zfs-share.service; enabled; vendor preset: enabled)
    
    Active: active (exited) since Mon 2021-05-10 12:36:29 UTC; 18min ago
    
     
3.8. Смотрим что у нас с дисками на ВМ.

    NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    
    sda                       8:0    0   40G  0 disk 
    
    ├─sda1                    8:1    0    1M  0 part 
    
    ├─sda2                    8:2    0    1G  0 part /boot
    
    └─sda3                    8:3    0   39G  0 part 
    
    ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
    
    └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
    
    sdb                       8:16   0   10G  0 disk 
    
    sdc                       8:32   0    2G  0 disk 
    
    sdd                       8:48   0    1G  0 disk 
    
    sde                       8:64   0    1G  0 disk 

    
    
3.9. Создадим пул myzfs содержащий диск /dev/sdc и кэш на дисках  /dev/sdd /dev/sde
    
    zpool create myzfs /dev/sdc cache /dev/sdd /dev/sde

3.10. Смотим что получилось.

    [root@localhost log]# zpool status -v
    
    pool: myzfs
    
    state: ONLINE
    
    config:
        NAME        STATE     READ WRITE CKSUM
        
        myzfs       ONLINE       0     0     0
        
          sdc       ONLINE       0     0     0
          
        cache
        
          sdd       ONLINE       0     0     0
          
          sde       ONLINE       0     0     0

    errors: No known data errors

3.11. Добавляем /dev/sdb в пул myzfs

    [root@localhost opt]# zpool add myzfs /dev/sdb

3.12. Смотрим размер пространства в пуле myzfs. Точка монтирования по умолчанию /myzfs

[root@localhost opt]# df -h

    Filesystem                       Size  Used Avail Use% Mounted on

    devtmpfs                         109M     0  109M   0% /dev

    tmpfs                            118M     0  118M   0% /dev/shm

    tmpfs                            118M  4.6M  113M   4% /run

    tmpfs                            118M     0  118M   0% /sys/fs/cgroup

    /dev/mapper/VolGroup00-LogVol00   38G  1.5G   37G   4% /

    /dev/sda2                       1014M   88M  927M   9% /boot

    tmpfs                             24M     0   24M   0% /run/user/1000

    myzfs                             12G  128K   12G   1% /myzfs


    
### 3.13. Так как /opt пустая папка - выполнил перенос /home на myzfs (pool zfs)    
    
3.13.1 Копируем данные из папки /home
        
        [root@localhost myzfs]#cp -aR /home/* /myzfs

3.13.2 Удаляем данные из папки home

        [root@localhost myzfs]#rm -rf /home/*

3.13.3 Проверяем что впапке /home -> пусто

    [root@localhost myzfs]# ls -al /home

        total 0
        
        drwxr-xr-x.  2 root root   6 May 10 13:53 .
        
        dr-xr-xr-x. 18 root root 237 May 10 13:21 ..
    
3.13.4 Размонтирвем myzfs (pool zfs)

    [root@localhost myzfs]# umount /myzfs

3.13.4 Задаем новую точку монтирования для myzfs

    [root@localhost /]# zfs set mountpoint=/home myzfs

3.13.5 Выполняем монтирование myzfs

    [root@localhost /]# zfs mount -a 

3.13.6 Смотрим что получилось:

    [root@localhost /]# df -h (myzfs примонтирован к /home)
    
        Filesystem                       Size  Used Avail Use% Mounted on
        
        devtmpfs                         109M     0  109M   0% /dev
        
        tmpfs                            118M     0  118M   0% /dev/shm
        
        tmpfs                            118M  4.6M  113M   4% /run
        
        tmpfs                            118M     0  118M   0% /sys/fs/cgroup
        
        /dev/mapper/VolGroup00-LogVol00   38G  1.5G   37G   4% /
        
        /dev/sda2                       1014M   88M  927M   9% /boot
        
        tmpfs                             24M     0   24M   0% /run/user/1000
        
        myzfs                             12G  128K   12G   1% /home
    
    [root@localhost /]# ls -al /home
        total 2
        drwxr-xr-x.  3 root    root      3 May 10 13:53 .
        
        dr-xr-xr-x. 17 root    root    224 May 10 13:54 ..
        
        drwx------.  3 vagrant vagrant   7 May 10 11:38 vagrant

    [root@localhost /]# exit
       
    [vagrant@localhost ~]$ pwd
    /home/vagrant

 3.13.7 Reboot ВМ и смотрим.
    [vagrant@localhost ~]$ df -h
    
        Filesystem                       Size  Used Avail Use% Mounted on
        
        devtmpfs                         109M     0  109M   0% /dev
        
        tmpfs                            118M     0  118M   0% /dev/shm
        
        tmpfs                            118M  4.6M  113M   4% /run
        
        tmpfs                            118M     0  118M   0% /sys/fs/cgroup
        
        /dev/mapper/VolGroup00-LogVol00   38G  1.5G   37G   4% /
        
        /dev/sda2                       1014M   88M  927M   9% /boot
        
        myzfs                             12G  128K   12G   1% /home
        
        tmpfs                             24M     0   24M   0% /run/user/1000

 
   [root@localhost ~]# zfs mount

        myzfs                           /home
 
    [root@localhost ~]# cd /home/
    
    [root@localhost home]# ls -al
    
        total 3
        
        drwxr-xr-x.  4 root       root         4 May 10 14:14 .
        
        dr-xr-xr-x. 17 root       root       224 May 10 13:54 ..
        
        drwx------.  2 asarafanov asarafanov   5 May 10 14:14 asarafanov
        
        drwx------.  3 vagrant    vagrant      7 May 10 11:38 vagrant
    
### 3.14. Работа со snapshots.

 3.14.1. Создадим 2 каталалога. В одном 200 файлов, в другом 100
   
    [root@localhost home]# mkdir /home/test-dir
    
    [root@localhost home]# touch /home/test-dir/file{1..200}

    [root@localhost home]# mkdir /home/test-dir1
    
    [root@localhost home]# touch /home/test-dir1/file{1..100}

3.14.2. Создадим снапшот

    [root@localhost /]# zfs snapshot  myzfs@test1

3.14.3. Проверяем создал ли снапшот
    [root@localhost /]# zfs list -t snapshot -r myzfs
    
    NAME          USED  AVAIL     REFER  MOUNTPOINT
    
    myzfs@test1     0B      -      258K  -

3.14.4 Удаляем один каталог 

        rm -rf /home/test-dir
        

    [root@localhost /]# ls -al /home/
    
    total 5
    
    drwxr-xr-x.  5 root       root         5 May 10 14:45 .
    
    dr-xr-xr-x. 17 root       root       224 May 10 13:54 ..
    
    drwx------.  2 asarafanov asarafanov   5 May 10 14:14 asarafanov
    
    drwxr-xr-x.  2 root       root       102 May 10 14:27 test-dir1
    
    drwx------.  3 vagrant    vagrant      7 May 10 11:38 vagrant

3.14.5. Восстанавливаем данные из снапшота myzfs@test1
 
    [root@localhost /]# zfs rollback myzfs@test1
    
3.14.6 Проверяем восстановление:    
    [root@localhost /]# ls -al /home/
    
    total 10
    
    drwxr-xr-x.  6 root       root         6 May 10 14:26 .
    
    dr-xr-xr-x. 17 root       root       224 May 10 13:54 ..
    
    drwx------.  2 asarafanov asarafanov   5 May 10 14:14 asarafanov
    
    drwxr-xr-x.  2 root       root       202 May 10 14:26 test-dir
    
    drwxr-xr-x.  2 root       root       102 May 10 14:27 test-dir1
    
    drwx------.  3 vagrant    vagrant      7 May 10 11:38 vagrant

    [root@localhost /]# ls -al /home/test-dir/ | wc -l
    
    203
    
    [root@localhost /]# 
 
    



