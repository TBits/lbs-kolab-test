Format: 1.0
Source: pykolab
Binary: pykolab, kolab-cli, kolab-conf, kolab-saslauthd, kolab-server, kolab-telemetry, kolab-xml, wallace
Architecture: all
Version: 0.7~dev20140625-0~kolab1
Maintainer: Jeroen van Meeuwen (Kolab Systems) <vanmeeuwen@kolabsys.com>
Uploaders: Paul Klos <kolab@klos2day.nl>
Homepage: http://www.kolab.org
Standards-Version: 3.9.3
Vcs-Git: git://git.kolab.org/git/pykolab
Build-Depends:  autotools-dev,
                debhelper (>= 7.0.50~),
                dh-autoreconf,
                gawk,
                gettext,
                intltool,
                libcroco3,
                libexpat1,
                libglib2.0-0,
                libglib2.0-dev,
                libpcre3,
                libssl-dev,
                libunistring0,
                libxml-parser-perl,
                libxml2,
                mime-support,
                python (>= 2.6~),
                python-icalendar,
                python-minimal,
                python-nose,
                python-support,
                univention-config-dev | bash
Package-List: 
 kolab-cli deb python optional
 kolab-conf deb python optional
 kolab-saslauthd deb python optional
 kolab-server deb python optional
 kolab-telemetry deb python optional
 kolab-xml deb python optional
 pykolab deb python optional
 wallace deb python optional
Files: 
 00000000000000000000000000000000 0 pykolab-0.7.tar.gz
 00000000000000000000000000000000 0 debian.tar.gz
