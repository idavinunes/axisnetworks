SCRIPT DE INSTALAÇÂO E TEMA E TRADUÇÂO 
AXIS NETWORKS

INSTALAÇÂO ISSABEL

centos 7 netstall

yum update

yum -y install wget


wget -O - http://repo.issabel.org/issabel4-netinstall.sh | bash


Para utilizar o tema axisnetworks é traduzir os audios utilize o script


wget -O - https://raw.githubusercontent.com/daviguitarra20/axisnetworks/main/temaxis.sh | bash

para tradução automatica 

wget -O - https://github.com/ibinetwork/IssabelBR/raw/master/patch-issabelbr.sh | bash



INSTALAÇÃO FREEPBX

yum install wget -y; wget -O - https://raw.githubusercontent.com/ibinetwork/freepbx_install/master/freepbx14_centos7_install.sh | bash
