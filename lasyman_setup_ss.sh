
#setup ss-panel 
function setup_sspanel()
{
	PANEL_ROOT=/root/ss-panel
	echo -e "download ss-panel ...\n"
	cd /root
	git clone https://github.com/lasyman/ss-panel.git
	#import pannel sql
	for mysql in ${SQL_FILES}
	do
		import_panel_sql="source ${PANEL_ROOT}/sql/${mysql}"
		mysql_op "${import_panel_sql}"
	done
	#modify config
	echo -e "modify lib/config-simple.php...\n"
	if [ -f "${PANEL_ROOT}/lib/config-simple.php" ];then
		mv ${PANEL_ROOT}/lib/config-simple.php ${PANEL_ROOT}/lib/config.php
	fi
	sed -i "/DB_PWD/ s#'password'#'${ROOT_PASSWD}'#" ${PANEL_ROOT}/lib/config.php
	sed -i "/DB_DBNAME/ s#'db'#'${DB_NAME}'#" ${PANEL_ROOT}/lib/config.php
	cp -rd ${PANEL_ROOT}/* /var/www/html/
	rm -rf /var/www/html/index.html
}

#start shadowsocks server
function start_ss()
{
	if [[ $UBUNTU -eq 1 ]];then
		service apache2 restart
	elif [[ $CENTOS -eq 1 ]];then
		/etc/init.d/httpd start
	fi
	if [[ $? != 0 ]];then
		echo "Web server restart failed, please check!"
		echo "ERROR!!!"
		exit 1
	fi
	cd /root/shadowsocks/shadowsocks
	nohup python server.py > /dev/null 2>&1 &
	echo "setup firewall..."
	setup_firewall
	#add start-up
	echo "cd /root/shadowsocks/shadowsocks;python server.py > /dev/null 2>&1 &" >> /etc/rc.d/rc.local
	echo "/etc/init.d/httpd start" >> /etc/rc.d/rc.local
	echo "/etc/init.d/mysqld start" >> /etc/rc.d/rc.local
	####
	echo ""
	echo "========================================================================e"
	echo "congratulations, shadowsocks server starting..."
	echo "========================================================================"
	echo "The log file is in /var/log/shadowsocks.log..."
	echo "type your ip into your web browser, you can see the web, also you can configure that at '/var/www/html'"
	echo "========================================================================"
}

#====================
# main
#
#judge whether root or not
if [ "$UID" -eq 0 ];then
read -p "(Please input New MySQL root password):" ROOT_PASSWD
if [ "$ROOT_PASSWD" = "" ]; then
echo "Error: Password can't be NULL!!"
exit 1
fi
	install_soft_for_each
	setup_manyuser_ss
	setup_sspanel
	start_ss
else
	echo -e "please run it as root user again !!!\n"
	exit 1
fi
