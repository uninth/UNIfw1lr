# specfile generated by rpmerizor (http://sourceforge.net/projects/rpmerizor/)

# if you are using __spec_only and want to build rpm package
# after, from command line, you have to use the following syntaxe
# rpmbuild -bb --buildroot=/tmp/rpmerizor_buildroot your_specfile.spec

AutoReqProv: no

# for compatibility with old md5 digest
# %global _binary_filedigest_algorithm 1
# %global _source_filedigest_algorithm 1

%define defaultbuildroot /
# Do not try autogenerate prereq/conflicts/obsoletes and check files
%undefine __check_files
%undefine __find_prereq
%undefine __find_conflicts
%undefine __find_obsoletes
# Be sure buildpolicy set to do nothing
%define __spec_install_post %{nil}
# Something that need for rpm-4.1
%define _missing_doc_files_terminate_build 0

%define name    UNIfw1lr
%define version 1.0
%define release 12

Summary: Utility for check firewall log housekeeping
Name: %{name}
Version: %{version}
Release: %{release}
License: GPL
Group: root
Packager: Niels Thomas Haugaard, nth@i2.dk

%description
Newlog, log export, compression visualizing, and removal of firewall-1 logfile, version for GaIA, R76 and R77*

%prep
ln -s /lan/ssi/shared/software/internal/UNIfw1lr/src/GaIA/UNIfw1lr_rootdir /tmp/UNIfw1lr_rootdir

%clean
rm /tmp/UNIfw1lr_rootdir

%pre
# Just before the upgrade/install
if [ "$1" = "1" ]; then
	echo "pre: upgrade/install: Perform tasks to prepare for the initial installation"
	:
elif [ "$1" = "2" ]; then
	echo "pre: Perform whatever maintenance must occur before the upgrade begins"
	NOW=`/bin/date +%Y-%m-%d`
	tar cvfpz /tmp/UNIfw1lr-config-${NOW}.tgz /var/opt/UNIfw1lr/etc
	echo "Old config files saved as /tmp/UNIfw1lr-config-${NOW}.tgz"
fi

# post install script -- just before %files
%post
# Just after the upgrade/install
if [ "$1" = "1" ]; then
	echo "post: performing tasks for for the initial installation ... "
	/var/opt/UNIfw1lr/etc/fw1lr setup

elif [ "$1" = "2" ]; then
	# Perform whatever maintenance must occur after the upgrade has ended
	NOW=`/bin/date +%Y-%m-%d`
	if [ -f  /tmp/UNIfw1lr-config-${NOW}.tgz ]; then
		/bin/mv /tmp/UNIfw1lr-config-${NOW}.tgz /var/opt/UNIfw1lr/etc
		echo "Please compare with the new ones."
	fi
	if [ -f  /var/opt/UNIfw1lr/etc/httpd2.conf.rpmorig ]; then
		/bin/cp /var/opt/UNIfw1lr/etc/httpd2.conf.rpmorig /var/opt/UNIfw1lr/etc/httpd2.conf
	fi
	if [ -f  /var/opt/UNIfw1lr/etc/.listen_ip.txt.rpmorig ]; then
		/bin/cp /var/opt/UNIfw1lr/etc/.listen_ip.txt.rpmorig /var/opt/UNIfw1lr/etc/.listen_ip.txt
	fi
fi

# If the first argument to %preun and %postun is 1, the action is an upgrade.
# If the first argument to %preun and %postun is 0, the action is uninstallation.

# pre uninstall script
%preun
# Just after the upgrade/install
if [ "$1" = "1" ]; then
    echo "preun: upgrading ... (just after upgrade/install) ... "
	/var/opt/UNIfw1lr/etc/fw1lr setup
elif [ "$1" = "0" ]; then
    # uninstallation
	echo "preun: uninstallation, stopping server ... "
	/etc/init.d/fw1log stop
	echo "Removing /etc/init.d/fw1lr"
	chkconfig --del fw1lr
	/bin/rm -f /etc/init.d/fw1lr
	echo "Please remove the follwing directories yourself, they contain configuration and datafiles:"
	echo "/var/opt/UNIfw1lr /var/log/UNIfw1lr"
fi

# All files below here - special care regarding upgrade for the config files
%files
%config /var/opt/UNIfw1lr/etc/fw1logrotate.conf
%config /var/opt/UNIfw1lr/etc/httpd2.conf
%config /var/opt/UNIfw1lr/etc/.listen_ip.txt
/var/opt/UNIfw1lr