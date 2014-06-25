tar xzf ~/sources/master.tar.gz
cd KolabScripts-master/kolab3.1
echo "y" | ./reinstall.sh || exit -1

./initSetupKolabPatches.sh
setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test || exit -1
service kolabd restart
./initSSL.sh || exit -1
./initMultiDomain.sh || exit -1
./initMailForward.sh || exit -1
./initMailCatchall.sh || exit -1
./initTBitsISP.sh || exit -1
cd ..

# install python selenium for the tests
if [ -f /etc/centos-release ]
then
  yum -y install python-setuptools || exit -1
  cachepath=/var/cache/yum
else
  if [ -f /etc/lsb-release ]
  then
    apt-get install -y python-setuptools || exit -1
    cachepath=/var/cache/apt
  else
    if [ -f /etc/debian_version ]
    then
      apt-get install -y python-setuptools || exit -1
      cachepath=/var/cache/apt
    fi
  fi
fi

easy_install selenium || exit -1
if [ ! -f $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 ]
then
  wget -O $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-x86_64.tar.bz2 || exit -1
fi
tar xjf $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2
cp phantomjs-1.9.2-linux-x86_64/bin/phantomjs /usr/bin || exit -1

cd pySeleniumTests
for f in *.py; do ./$f; done

# tell the LBS that the calling python script can continue
echo "LBSScriptFinished"
