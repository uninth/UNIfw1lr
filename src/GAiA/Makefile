#
# Makefile for UNIfw1lr
#

VERSION		= 1.0
RELEASE		= 12

binfiles = default.report.sh fw1lr-wrapper.sh mkindex	mk.index.sh run-all.sh fw1logrotate.pl	mkindex 
etcfiles = fw1lr httpd2.conf.tmpl htmlhead.txt fw1logrotate.conf httpd2.conf .listen_ip.txt

otherfiles = get_firewall_logs.sh

COMPILEHOST	= rhes3.ssi.i2.dk
HOSTNAME	= `hostname`

TARGETDIR	= /lan/ssi/shared/software/internal/UNIfw1lr/RPM
WORKDIR		= $(TARGETDIR)/src/GaIA

ROOTDIR		= $(WORKDIR)/UNIfw1lr_rootdir
GROUP		= root
NAME		= UNIfw1lr

ARCH		= i386
REDHAT		= /usr/src/redhat
BUILDDIR	= $(REDHAT)/RPMS/$(ARCH)/
SPFILE		= UNIfw1lr-$(VERSION)-$(RELEASE).spec
SPTEMPLATE	= unifw1lr.spec.template
SPECFILE	= $(REDHAT)/SPECS/$(SPFILE)
RPMBR		= /tmp/UNIfw1lr_rootdir

TARGET		= $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm
INSTALL		= INSTALL-$(NAME)-$(VERSION)-$(RELEASE).md
INST_HTML   = INSTALL-$(NAME)-$(VERSION)-$(RELEASE).html

# RPMDIR		= /lan/ssi/shared/software/internal/RPM
RPMDIR          = ../../RPM

all: $(TARGET)

clean:
	/bin/rm -fr $(RPMBR) /tmp/UNIfw1lr_rootdir $(ROOTDIR) UNIfw1lr_rootdir

$(INSTALL): INSTALL.md
	@sed "									\
		s/__VERSION__/$(VERSION)/g;			\
		s/__RELEASE__/$(RELEASE)/g;			\
		s%__TARGET__%$(TARGET)%g;			\
		s%__NAME__%$(NAME)%g;			\
		" < INSTALL.md > $(INSTALL)

updatewiki: $(INSTALL)
        # copy user documentation to wiki
		ssh root@office 'cd /var/www/volatile/software/unifw1lr && /bin/rm -fr *pdf UNIfw1lr-documentation'
		mkd2html -css UNIfw1lr-documentation/assets/CSS/i2-Book.css $(INSTALL) # makes $(INST_HTML)
		scp $(INST_HTML) root@office:/var/www/volatile/software/unifw1lr/INSTALL.html
		cd ./UNIfw1lr-user-documentation.textbundle && rsync -avzH -e ssh UNIfw1lr.html UNIfw1lr.pdf assets root@office:/var/www/volatile/software/unifw1lr/UNIfw1lr-documentation/
		cd ./UNIfw1lr-user-documentation.textbundle && rsync -avzH -e ssh assets/img/UNIfw1lr-coverpage.png root@office:/var/www/dokuwiki/data/media/firewall_support/gaia_pkgs/unifw1lr-coverpage.png

check:
	@if [ $(HOSTNAME) == $(COMPILEHOST) ];	then echo compile host ok; else echo not compile host; exit 1; fi
	@if [ -d $(WORKDIR) ]; then echo wokdir ok; else echo workdir not found; exit 1; fi
	@echo $@ done

$(SPFILE): $(SPTEMPLATE) 
	@sed "									\
		s/__VERSION__/$(VERSION)/g;			\
		s/__RELEASE__/$(RELEASE)/g;			\
		s%__ROOTDIR__%$(ROOTDIR)%g;			\
		" < $(SPTEMPLATE)  > $(SPFILE)
	@echo $@ done
	
build: $(INSTALL) $(SPFILE)
	@rpmbuild -bb --buildroot=$(RPMBR) $(SPFILE)
	@mv $(BUILDDIR)/$(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm .

info: build
	@echo "rpm content....: rpm -lpq $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm"
	@echo "rpm install....: rpm -Uvh $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm"
	@echo "rpm check deps.: rpm -qpR $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm"

$(TARGET):	dirs ext doc bin etc info 
	@/bin/rm -f $(TARGETDIR)/$(TARGET) $(TARGETDIR)/$(INSTALL)
	@/bin/rm -f $(RPMDIR)/$(TARGET) $(RPMDIR)/$(INSTALL)
	/bin/mv $(INSTALL) $(RPMDIR)/
	/bin/mv $(TARGET) $(RPMDIR)/

etc: $(etcfiles)
	@for f in $(etcfiles); do	\
		/usr/bin/install -c -m 644 $$f UNIfw1lr_rootdir/var/opt/UNIfw1lr/etc/$$f;	\
	done
	@chmod 555 UNIfw1lr_rootdir/var/opt/UNIfw1lr/etc/fw1lr

bin: $(binfiles)
	@for f in $(binfiles); do	\
		/usr/bin/install -c -m 555 $$f UNIfw1lr_rootdir/var/opt/UNIfw1lr/bin/$$f;	\
	done

doc:
	@cp UNIfw1lr-user-documentation.textbundle/UNIfw1lr.pdf UNIfw1lr_rootdir/doc/
	@cp $(otherfiles) UNIfw1lr_rootdir/doc/
	mkdir -p UNIfw1lr_rootdir/doc/licenses
	cp LICENSE UNIfw1lr_rootdir/doc/licenses
	cp external/fwlogsum-5.0.2/README	UNIfw1lr_rootdir/doc/licenses/README-fwlogsum-5.0.2.txt
	@chmod 744 UNIfw1lr_rootdir/doc/*

dirs:
	@mkdir -p UNIfw1lr_rootdir/doc
	@mkdir -p UNIfw1lr_rootdir/etc
	@mkdir -p UNIfw1lr_rootdir/etc/cron.d
	@mkdir -p UNIfw1lr_rootdir/var/opt/UNIfw1lr/bin
	@mkdir -p UNIfw1lr_rootdir/var/opt/UNIfw1lr/docs
	@mkdir -p UNIfw1lr_rootdir/var/opt/UNIfw1lr/etc
	@mkdir -p UNIfw1lr_rootdir/var/opt/UNIfw1lr/log
	@mkdir -p UNIfw1lr_rootdir/var/opt/UNIfw1lr/tmp
	@cd UNIfw1lr_rootdir/var/opt/UNIfw1lr; test -h fwlogsum || ln -s fwlogsum-5.0.2 fwlogsum

ext: dirs
	cp -r external/* UNIfw1lr_rootdir/var/opt/UNIfw1lr
