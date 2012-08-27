
# Installation procedure for UNIfw1lr-1.0-12.i386.rpm
    Package name: UNIfw1lr-1.0-12.i386.rpm
    Version     : 1.0
    Release     : 12

## Prerequisite
Install UNItools first, as perl is needed. Notice: the package does NOT
check if UNItools *is installed*.

## Installation
Copy ``UNIfw1lr-1.0-12.i386.rpm`` to the management station (firewall), and install the package

        td -x UNIfw1lr-1.0-12.i386.rpm external-interface
        td external-interface
        rpm -Uvh /var/tmp/UNIfw1lr-1.0-12.i386.rpm

   This will configure the web-server to run on port 127.0.0.1 (default/first time)
   or any prev. configured IP address. Change address in /var/opt/UNIfw1lr/etc/httpd2.conf
   or /var/opt/UNIfw1lr/etc/.listen_ip.txt, then re-run

       /var/opt/UNIfw1lr/etc/fw1lr setup

       /var/opt/UNIfw1lr/etc/fw1lr start

Check that the server is running - and check with a browser::

      /etc/init.d/fw1log status

      links https://`cat /var/opt/UNIfw1lr/etc/.listen_ip.txt`:9876

Apache logs errors in ``/var/log/httpd2_error_log``.

Default is to keep all logfiles 10 days uncompressed and aditional 10 days compressed.
This can be changed in ``/var/opt/UNIfw1lr/etc/fw1logrotate.conf``.

##Known issues
A known issue with _Apache_ is the _Apache Error #28 No space left on device_ which has nothing to do with
space but turns out to be left over semaphore arrays see
http://blog.ryantan.net/2010/04/apache-error-28-no-space-left-on-device/

In ``fw1lr-wrapper.sh`` (ececuted once a day from ``/etc/cron.d/fw1lr``) the following has been added:

        NUMS=`ipcs -s | grep nobody|wc -l | tr -d ' '`
		if [ "${NUMS}" -gt 50 ]; then
			ipcs -s | grep nobody | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
			logit "removing apache left over semaphore arrays - found $NUMS expected way below 50"
		fi

This may/may not fix apache semaphore problems.

##Uninstallation

Remove the package with:

	rpm -e --nodeps UNIfw1lr

You may have to delete files below ``/var/opt/UNIfw1lr``after the un-installation.

##Note

This document is in RCS and build with make

#RPM info

View rpm content with

    rpm -lpq UNIfw1lr



