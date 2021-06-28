#!/bin/bash
sudo usermod -aG wheel vagrant
sudo echo "%vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd	
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo setenforce 0


			