cd kolab3_tbits_scripts-master/kolab3.1
echo "y" | ./reinstall.sh
if [ $? -ne 0 ]
then
  exit 1
fi

./initSetupKolabPatches.sh
setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test
service kolabd restart
./initSSL.sh
./initMultiDomain.sh
./initMailForward.sh
./initMailCatchall.sh
./initTBitsISP.sh
cd ..

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
  else
    if [ -f /etc/debian_version ]
    then
      apt-get install -y python-setuptools
      cachepath=/var/cache/apt
    fi
  fi
fi

easy_install selenium
if [ ! -f $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 ]
then
  wget -O $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2 https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-x86_64.tar.bz2
fi
tar xjf $cachepath/phantomjs-1.9.2-linux-x86_64.tar.bz2
cp phantomjs-1.9.2-linux-x86_64/bin/phantomjs /usr/bin

cd pySeleniumTests
for f in *.py; do ./$f; done

# tell the LBS that the calling python script can continue
echo "LBSScriptFinished"
