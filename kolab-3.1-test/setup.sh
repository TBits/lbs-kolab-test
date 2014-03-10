wget https://github.com/tpokorra/kolab3_tbits_scripts/archive/master.tar.gz
tar xzf master.tar.gz
cd kolab3_tbits_scripts-master/kolab3.1
echo "y" | ./reinstall.sh
if [ $? -ne 0 ]
then
  exit 1
fi

./initSetupKolabPatches.sh
setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test
service kolabd restart
./initMultiDomain.sh
./initMailForward.sh
./initMailCatchall.sh

# install python selenium for the tests
if [ -f /etc/centos-release ]
then
  yum -y install python-setuptools
  cachepath=/var/cache/yum
else
  if [ -f /etc/lsb-release ]
  then
    apt-get install -y python-setuptools
    cachepath=/var/cache/apt
  fi
fi

easy_install selenium
if [ ! -f $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 ]
then
  wget -O $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-x86_64.tar.bz2
fi
tar xjf $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2
cp phantomjs-1.9.2-linux-x86_64/bin/phantomjs /usr/bin
