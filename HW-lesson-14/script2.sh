#!/bin/bash
su - vagrant
ssh-keygen -q -t rsa -N '' -f /home/vagrant/.ssh/id_rsa <<<y 2>&1 >/dev/null 
chown -R vagrant:vagrant /home/vagrant/.ssh
ssh-keyscan 192.168.11.191 >> /home/vagrant/.ssh/known_hosts
