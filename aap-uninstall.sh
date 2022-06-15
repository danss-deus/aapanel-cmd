#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Remove_Bt(){
	if [ ! -f "/etc/init.d/bt" ] || [ ! -d "/www/server/panel" ]; then
		echo -e "This server does not install aaPanel"
		exit;
	fi

	if [ -f "/etc/init.d/bt_syssafe" ]; then
		echo -e "This server is installed with aaPanel system hardening plugin, may not be able to uninstall properly, please execute the uninstall command after the panel is uninstalled!"
		exit;
	fi

	if [ -f "/etc/init.d/bt_tamper_proof" ]; then
		echo -e "This server is installed with aaPanel website-tamper-proof plugin, may not be able to uninstall properly, please execute the uninstall command after the panel is uninstalled!"
		exit;
	fi

	/etc/init.d/bt stop
	if [ -f "/usr/sbin/chkconfig" ];then
		chkconfig --del bt
	elif [ -f "/usr/sbin/update-rc.d" ];then
		update-rc.d -f bt remove
	fi
	rm -rf /www/server/panel
	rm -f /etc/init.d/bt
	echo -e "aaPanel successfully uninstalled"
}
Remove_Rpm(){
	echo -e "Find installed packages..."
	for lib in bt-nginx bt-httpd bt-mysql bt-curl bt-AliSQL AliSQL-master bt-mariadb bt-php-5.2 bt-php-5.3 bt-php-5.4 bt-php-5.5 bt-php-5.6 bt-php-7.0 bt-php-7.1
	do
		rpm -qa |grep ${lib} > ${lib}.pl
		libRpm=`cat ${lib}.pl`
		if [ "${libRpm}" != "" ]; then
			rpm -e ${libRpm} --nodeps > /dev/null 2>&1
			echo -e ${lib} "\033[32mclean\033[0m"
		fi
		rm -f ${lib}.pl
	done
	yum remove bt-openssl* -y
	yum remove bt-php* -y
	echo -e "Clean up"
}

Remove_Service(){
	servicePath="/www/server"

	for service in nginx httpd mysqld pure-ftpd tomcat redis memcached mongodb pgsql tomcat tomcat7 tomcat8 tomcat9 php-fpm-52 php-fpm-53 php-fpm-54 php-fpm-55 php-fpm-56 php-fpm-70 php-fpm-71 php-fpm-72 php-fpm-73
	do
		if [ -f "/etc/init.d/${service}" ]; then
			/etc/init.d/${service} stop
			if [ -f "/usr/sbin/chkconfig" ];then
				chkconfig  --del ${service}
			elif [ -f "/usr/sbin/update-rc.d" ];then
				update-rc.d -f ${service} remove
			fi

			if [ "${service}" = "mysqld" ]; then
			 	rm -rf ${servicePath}/mysql
			 	rm -f /etc/my.cnf
			elif [ "${service}" = "httpd" ]; then
				rm -rf ${servicePath}/apache
			elif [ "${service}" = "memcached" ]; then
				rm -rf /usr/local/memcached
			elif [ -d "${servicePath}/${service}" ]; then
				rm -rf ${servicePath}/${service}
			fi 
			rm -f /etc/init.d/${service}
			echo -e ${service} "\033[32mclean\033[0m"
		fi
	done


	[ -d "${servicePath}/php" ] && rm -rf ${servicePath}/php
	if [ -d "${servicePath}/phpmyadmin" ]; then
		rm -rf ${servicePath}/phpmyadmin
		echo -e "phpmyadmin" "\033[32mclean\033[0m"
	fi

	if [ -d "${servicePath}/nvm" ]; then
		source /www/server/nvm/nvm.sh
		pm2 stop all
		rm -rf ${servicePath}/nvm
		sed -i "/NVM/d" /root/.bash_profile
		sed -i "/NVM/d" /root/.bashrc
		echo -e "node.js" "\033[32mclean\033[0m"
	fi

	echo "Clear aaPanel runtime environment complete"
}
Remove_Data(){
	rm -rf /www/server/data
	rm -rf /www/wwwlogs
	rm -rf /www/wwwroot
}
 
#echo -e "What you want to do ?(Choose 1-2, Default: 1)"
echo "1) Uninstall aaPanel"  
echo "2) Uninstall aaPanel and operating environment (may affect site, database and other data)"
#echo "3) Uninstall aaPanel and operating environment and clear all site related data"
echo "*Please check whether the security software is turned off, otherwise it may cause the uninstallation to fail. "
echo "=================================================" 
read -p "Please select the operation you want to perform (Default: 1): " action; 

case $action in
	'1')
		Remove_Bt
		;;
	'2')
		if [ -f "/usr/bin/yum" ] && [ -f "/usr/bin/rpm" ]; then
			Remove_Rpm
		fi
		Remove_Service
		Remove_Bt
		;;
	*)
		Remove_Bt
		;;
esac
