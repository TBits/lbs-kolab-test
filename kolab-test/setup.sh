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

function exitWithErrorCode() {
  # need to stop services because some of them have an open output pipe, and ssh would not disconnect
  service kolabd stop
  service kolab-saslauthd stop
  service cyrus-imapd stop
  service dirsrv stop
  service wallace stop
  service clamd stop
  service amavisd stop
  service mysqld stop
  service httpd stop

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
./initSetupKolabPatches.sh
echo 2 | setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test || exit -1
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
