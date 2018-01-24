#!/bin/bash

branch=KolabWinterfell
if [ ! -z "$1" ]; then
  branch=$1
fi

# install some required packages
dist="unknown"
if [ -f /etc/centos-release ]
then
  dist="CentOS"
  release="7"
  yum -y install epel-release
  yum -y install python-setuptools python-unittest2 wget which bzip2 mailx selinux-policy-targeted Xvfb python2-pip gtk3 dbus-glib || exit 1
  sed -i 's/enforcing/permissive/g' /etc/selinux/config
  cachepath=/var/cache/yum
elif [ -f /etc/fedora-release ]
then
  dist="Fedora"
  dnf -v -y install python-setuptools python-unittest2 wget which bzip2 mailx policycoreutils selinux-policy-targeted python2-pip || exit 1
  sed -i 's/enforcing/permissive/g' /etc/selinux/config
  cachepath=/var/cache/dnf
else
  # avoid problems installing postfix
  export DEBIAN_FRONTEND=noninteractive
  debconf-set-selections <<< "postfix postfix/mailname string " `hostname -f`
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
  # Ubuntu
  if [ -f /etc/lsb-release ]
  then
    dist="Ubuntu"
    apt-get install -y python-setuptools python-unittest2 wget bzip2 mailutils || exit 1
    cachepath=/var/cache/apt
  else
    # Debian
    if [ -f /etc/debian_version ]
    then
      dist="Debian"
      apt-get install -y python-setuptools python-unittest2 wget bzip2 mailutils python-pip xvfb libgtk-3-0 || exit 1
      cachepath=/var/cache/apt
    fi
  fi
fi

function exitWithErrorCode() {
  # need to stop services because some of them have an open output pipe, and ssh would not disconnect
  if [[ "$dist" == "CentOS" || "$dist" == "Fedora" ]]; then
    systemctl stop kolabd
    systemctl stop kolab-saslauthd
    systemctl stop cyrus-imapd
    systemctl stop dirsrv.target
    systemctl stop wallace
    systemctl stop clamd@amavisd
    systemctl stop amavisd
    systemctl stop mariadb
    systemctl stop httpd
  else
    systemctl stop kolab-server
    systemctl stop kolab-saslauthd
    systemctl stop cyrus-imapd
    systemctl stop dirsrv
    systemctl stop wallace
    systemctl stop clamav-daemon
    systemctl stop amavis
    systemctl stop mysql
    systemctl stop apache2
  fi 

  echo "========= /var/log/kolab-webadmin/errors ======="
  cat /var/log/kolab-webadmin/errors
  echo "========= /var/log/kolab-webadmin/console ======="
  cat /var/log/kolab-webadmin/console

  exit $1
}


# install python selenium for the tests
pip install selenium pyvirtualdisplay || exit 1

# download latest firefox and geckodriver
cd /root
wget --tries=3 https://download-installer.cdn.mozilla.net/pub/firefox/releases/57.0/linux-x86_64/en-US/firefox-57.0.tar.bz2 || exit -1
tar xjf firefox-57.0.tar.bz2
ln -s /root/firefox/firefox /usr/bin/firefox
wget --tries=3 https://github.com/mozilla/geckodriver/releases/download/v0.19.1/geckodriver-v0.19.1-linux64.tar.gz || exit -1
tar xzf geckodriver-v0.19.1-linux64.tar.gz
ln -s /root/geckodriver /usr/bin/geckodriver
cd -

wget --tries=3 -O $branch.tar.gz https://github.com/TBits/KolabScripts/archive/$branch.tar.gz || exit -1
tar xzf $branch.tar.gz
cd KolabScripts-$branch/kolab
echo "========= REINSTALL ==========="
echo "y" | ./reinstall.sh || exit 1

echo "========= setup-kolab ==========="
./initSetupKolabPatches.sh || exit 1
setup-kolab --default --mysqlserver=new --timezone=Europe/Berlin --directory-manager-pwd=test || exitWithErrorCode 1
h=`hostname`

# March 2017: at the moment the guam package is broken
guam=1
if [[ "$branch" == "KolabWinterfell" ]]
then
  if [[ "$dist" == "CentOS" || "$dist" == "Fedora" || "$dist" == "Debian" || "$dist" == "Ubuntu" ]]
  then
    guam=0
  fi
fi

# October 2017: guam crashes on start on Debian
if [[ "$branch" == "Kolab16" ]]
then
  if [[ "$dist" == "Debian" || "$dist" == "Ubuntu" ]]
  then
    guam=0
  fi
fi

# just check if the services are running
if [[ "$dist" == "CentOS" || "$dist" == "Fedora" ]]
then
  # do we have a guam package installed at all?
  if [[ "`rpm -qa | grep guam`" == "" ]]
  then
    guam=0
  fi
fi

# check if the services are running
systemctl status wallace || exitWithErrorCode 1
systemctl status cyrus-imapd || exitWithErrorCode 1
if [ $guam -eq 1 ]
then
  # only check for guam if it is enabled
  systemctl status guam || exitWithErrorCode 1
else
  ./disableGuam.sh
fi

if [ ! -d /tmp/SeleniumTests ]
then
  xvfb-run firefox -CreateProfile "SeleniumTests /tmp/SeleniumTests"
fi

echo "========= vanilla tests ==========="
cd ../pySeleniumTests
./configureKolabUserMailhost.py
./runTests.sh vanilla || exitWithErrorCode 1

echo "========= configure multidomain ==========="
cd ../kolab
./initSSL.sh ${h:`expr index $h .`} || exitWithErrorCode 1
./initMultiDomain.sh || exitWithErrorCode 1
./initMailForward.sh || exitWithErrorCode 1
./initMailCatchall.sh || exitWithErrorCode 1
./initSleepTimesForTest.sh

cd ../pySeleniumTests
echo "========= catchall and forwarding tests ==========="
./runTests.sh catchallforwarding || exitWithErrorCode 1
echo "========= multidomain tests ==========="
./runTests.sh multidomain || exitWithErrorCode 1

if [[ "$dist" == "Ubuntu" || "$dist" == "Debian" ]]; then
  # For Debian, there is a problem with the KolabUser Type, https://github.com/TBits/KolabScripts/issues/77
  # therefore we do not test the ISP patches
  exitWithErrorCode 0
fi

echo "========= configure ISP patches ==========="
cd ../kolab
./initTBitsISP.sh || exitWithErrorCode 1
# enable debugging
sed -r -i -e "s/\[kolab_wap\]/[kolab_wap]\ndebug_mode = WARNING/g" /etc/kolab/kolab.conf
# do not run initTBitsCustomizationsDE.sh because the tests expect an english user interface

echo "========= run all tests ==========="
cd ../pySeleniumTests
./runTests.sh all || exitWithErrorCode 1

# clean up running services, so that the ssh session can stop
exitWithErrorCode 0
