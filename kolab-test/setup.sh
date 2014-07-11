#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

# install some required packages
if [ -f /etc/centos-release ]
then
  yum -y install python-setuptools wget which bzip2 mail || exit 1
  cachepath=/var/cache/yum
else
  if [ -f /etc/lsb-release ]
  then
    apt-get install -y python-setuptools wget which bzip2 || exit 1
    cachepath=/var/cache/apt
  else
    if [ -f /etc/debian_version ]
    then
      apt-get install -y python-setuptools wget which bzip2 || exit 1
      cachepath=/var/cache/apt
    fi
  fi
fi

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
echo "y" | ./reinstall.sh || exit 1

./initSetupKolabPatches.sh
echo 2 | setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test || exit -1
h=`hostname`
./initSSL.sh ${h:`expr index $h .`} || exit 1

cd ../pySeleniumTests
./runTests.sh vanilla || exit 1

cd ../kolab
./initMultiDomain.sh || exit 1
./initMailForward.sh || exit 1
./initMailCatchall.sh || exit 1

cd ../pySeleniumTests
./runTests.sh multidomain || exit 1

cd ../kolab
./initTBitsISP.sh || exit 1
# do not run initTBitsCustomizationsDE.sh because the tests expect an english user interface

cd ../pySeleniumTests
./runTests.sh all || exit 1

# need to stop services because some of them have an open output pipe, and ssh would not disconnect
service kolabd stop
service kolab-saslauthd stop
service cyrus-imapd stop
service dirsrv stop
service wallace stop
service httpd stop

