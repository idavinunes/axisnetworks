   1  nano /etc/network/interfaces
auto ens18
iface ens18 inet static
address 10.0.0.11
netmask 255.255.255.0
gateway 10.0.0.1
    4  nano /etc/hosts
	127.0.0.1       localhost
    10.0.0.11       adlinux.mozi.com        adlinux
    5  nano /etc/apt/sources.list	
    6  apt update -y
    7  rebooy
    8  reboot
    9  ifconfig
   10  ping globo.com
   11  nano /etc/network/interfaces
   12  apt install samba winbind krb5-user krb5-config
   13  systemctl stop smbd nmbd winbind 
   14  systemctl disable smbd nmbd winbind 
   15  rm /etc/samba/smb.conf
   16  rm /etc/krb5.conf 
   17  samba-tool  domain provision --use-rfc2307 --interactive
   18  cp /var/lib/samba/private/krb5.conf  /etc/krb5.conf
   19  systemctl unmask samba-ad-dc.service
   20  systemctl enable samba-ad-dc.service
   21  nano /etc/resolv.conf 
   22  reboot
