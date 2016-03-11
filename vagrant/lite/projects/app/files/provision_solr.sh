#!/bin/bash
set -x

# INSTALL JAVA
if [ ! -d /usr/lib/jvm ]
then
yum install -y java
fi

# INSTALL SEARCH APP
if [ ! -d /opt/search-app ]
then
mkdir /opt/search-app
cd /opt/search-app
cp /vagrant/projects/app/files/search-app.jar .
cp /vagrant/projects/app/files/search.properties .
fi

# INSTALL SOLR AND LOAD DATA
if [ ! -e /opt/solr-5.5.0 ] 
then
curl -O http://mirror.ox.ac.uk/sites/rsync.apache.org/lucene/solr/5.5.0/solr-5.5.0.tgz
tar xzf solr-5.5.0.tgz solr-5.5.0/bin/install_solr_service.sh --strip-components=2
bash ./install_solr_service.sh solr-5.5.0.tgz
until $(curl --output /dev/null --silent --head --fail http://localhost:8983); do
    printf '.'
    sleep 5
done
su -l solr
cd /var/solr/data/
su -c "mkdir -p goodsentries/conf" solr
su -c "cp -r /vagrant/projects/app/solr/. /var/solr/data/goodsentries/conf" solr
curl 'http://localhost:8983/solr/admin/cores?action=CREATE&name=goodsentries&instanceDir=goodsentries'
service solr restart
until $(curl --output /dev/null --silent --head --fail http://localhost:8983); do
    printf '.'
    sleep 5
done
cd /vagrant/projects/app/files/
curl 'http://localhost:8983/solr/goodsentries/update?commit=true' --data-binary @data.json -H 'Content-type:application/json'
fi