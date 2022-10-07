#!/bin/bash
cd /var/www/html/themes/
wget  https://github.com/daviguitarra20/axisnetworks/archive/refs/heads/main.zip 
unzip main.zip
mv axisnetworks-main/ axisnetworks
rm -rf main.zip
clear