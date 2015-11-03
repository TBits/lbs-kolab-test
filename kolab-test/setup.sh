#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

# install some required packages
dist="unknown"
if [ -f /etc/centos-release ]
then
  dist="CentOS"
  yum -y install python-setuptools python-unittest2 wget which bzip2 mailx || exit 1
  cachepath=/var/cache/yum
elif [ -f /etc/fedora-release ]
then
  dist="Fedora"
  dnf -v -y install python-setuptools python-unittest2 wget which bzip2 mailx policycoreutils || exit 1
  cachepath=/var/cache/dnf
else
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
      apt-get install -y python-setuptools python-unittest2 wget bzip2 mailutils || exit 1
      cachepath=/var/cache/apt
    fi
  fi
fi

function exitWithErrorCode() {
  # need to stop services because some of them have an open output pipe, and ssh would not disconnect
  if [[ "$dist" == "CentOS" || "$dist" == "Fedora" ]]; then
    service kolabd stop
    service kolab-saslauthd stop
    service cyrus-imapd stop
    service dirsrv stop
    service wallace stop
    service clamd stop
    service amavisd stop
    service mysqld stop
    service httpd stop
  else
    service kolab-server stop
    service kolab-saslauthd stop
    service cyrus-imapd stop
    service dirsrv stop
    service wallace stop
    service clamav-daemon stop
    service amavis stop
    service mysql stop
    service apache2 stop
  fi 

  exit $1
}


# install python selenium for the tests
easy_install selenium || exit 1
phantomurl="https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2"
phantomfile=`basename $phantomurl`
if [ ! -f $cachepath/$phantomfile ]
then
  wget -O $cachepath/$phantomfile $phantomurl || exit 1
fi
tar xjf $cachepath/$phantomfile
mv phantomjs* phantomjs
cp phantomjs/bin/phantomjs /usr/bin || exit 1

wget -O $branch.tar.gz https://github.com/TBits/KolabScripts/archive/$branch.tar.gz
tar xzf $branch.tar.gz
cd KolabScripts-$branch/kolab
echo "========= REINSTALL ==========="
echo "y" | ./reinstall.sh || exit 1

echo "========= setup-kolab ==========="
./initSetupKolabPatches.sh || exit 1
setup-kolab --default --mysqlserver=new --timezone=Europe/Berlin --directory-manager-pwd=test || exitWithErrorCode 1
h=`hostname`

echo "========= vanilla tests ==========="
cd ../pySeleniumTests
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

echo "========= configure ISP patches ==========="
cd ../kolab
./initTBitsISP.sh || exitWithErrorCode 1
# do not run initTBitsCustomizationsDE.sh because the tests expect an english user interface

echo "========= run all tests ==========="
cd ../pySeleniumTests
./runTests.sh all || exitWithErrorCode 1

# clean up running services, so that the ssh session can stop
exitWithErrorCode 0
