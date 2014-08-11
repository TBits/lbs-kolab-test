#!/bin/bash

gitname=kolab-utils
while [ ! -f $gitname-git-master.tar.gz ]
do
    curl --retry 10 --retry-delay 30 -f -o $gitname-git-master.tar.gz https://git.kolab.org/$gitname/snapshot/$gitname-master.tar.gz || sleep 60
done
