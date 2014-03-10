wget https://github.com/tpokorra/kolab3_tbits_scripts/archive/master.tar.gz
tar xzf master.tar.gz
cd kolab3_tbits_scripts-master/kolab3.1
echo "y" | ./reinstall.sh
./initSetupKolabPatches.sh
setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test
service kolabd restart
./initMultiDomain.sh
./initMailForward.sh
./initMailCatchall.sh

# install python selenium for the tests
yum -y install python-setuptools
easy_install selenium
wget https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-x86_64.tar.bz2
tar xjf phantomjs-1.9.2-linux-x86_64.tar.bz
cp phantomjs-1.9.2-linux-x86_64/bin/phantomjs /usr/bin
