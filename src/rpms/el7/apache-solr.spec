Summary:            A standalone enterprise search server with a REST-like API
Name:               solr
Version:            5.5.0
Release:            1%{?dist}
Prefix:             /opt
Prefix:             /etc
License:            ASL2.0
Group:              Applications/Databases
Source:             http://mirror.ox.ac.uk/sites/rsync.apache.org/lucene/solr/%{version}/%{name}-%{version}.tgz
URL:                http://lucene.apache.org/solr
Requires:           java-1.8.0-openjdk

%define __os_install_post %{nil}

%description
Solr is highly reliable, scalable and fault tolerant, providing distributed 
indexing, replication and load-balanced querying, automated failover and 
recovery, centralized configuration and more. Solr powers the search and 
navigation features of many of the world's largest internet sites.

%build

%prep
%__rm -fr %{buildroot}
%__mkdir %{buildroot}
tar zxvf %{SOURCE0} -C %{buildroot}

%pre
if [ "$1" = 1 ]
then
  getent group solr >/dev/null || groupadd -r solr
  getent passwd solr >/dev/null || \
    useradd -r -g solr -md /home/solr -s /bin/bash -c "The Apache Solr user" solr
elif [ "$1" = 2 ]
then
  if [ -L "/opt/%{name}" ]
  then
    rm /opt/${name}
  fi
fi

%install
mkdir %{buildroot}/opt/
%__cp -r %{name}-%{version} %{buildroot}/opt/
%__ln_s %{name}-%{version} %{buildroot}/opt/%{name}

find %{buildroot}/opt/%{name}-%{version} -type d -print0 | xargs -0 chmod 0755
find %{buildroot}/opt/%{name}-%{version} -type f -print0 | xargs -0 chmod 0644
chmod -R 0755 %{buildroot}/opt/%{name}-%{version}/bin

mkdir -p %{buildroot}/%{_sysconfdir}/init.d/init.d
install -m 755 %{name}-%{version}/bin/init.d/solr \
  %{buildroot}/%{_sysconfdir}/init.d/solr
sed -i -e 's#SOLR_INSTALL_DIR=.*#SOLR_INSTALL_DIR="/opt/solr"#' \
  -e 's#SOLR_ENV=.*#SOLR_ENV="/etc/default/solr.in.sh"#' \
  -e 's#RUNAS=.*#RUNAS="solr"#' \
  -e 's#Provides:.*#Provides: solr#' %{buildroot}/%{_sysconfdir}/init.d/solr

install -m 755 -d %{buildroot}/%{_sysconfdir}/default
chmod 0755 %{buildroot}/%{_sysconfdir}/default

cat - > %{buildroot}/%{_sysconfdir}/default/solr.in.sh << __EOF__
SOLR_PID_DIR="%{_localstatedir}/%{name}"
SOLR_HOME="%{_localstatedir}/%{name}/data"
LOG4J_PROPS="%{_localstatedir}/%{name}/log4j.properties"
SOLR_LOGS_DIR="%{_localstatedir}/log/%{name}"
__EOF__

install -m 755 -d %{buildroot}/%{_localstatedir}/%{name}/data
install -m 755 -d %{buildroot}/%{_localstatedir}/%{name}/logs

install -m 755 %{name}-%{version}/server/solr/solr.xml %{buildroot}/%{_localstatedir}/%{name}/data/solr.xml

install -m 755 %{name}-%{version}/server/resources/log4j.properties %{buildroot}/%{_localstatedir}/%{name}/log4j.properties
sed -ie 's#solr.log=.*#solr.log=${solr.solr.home}/../logs#' %{buildroot}/%{_localstatedir}/%{name}/log4j.properties

find %{buildroot}/%{_localstatedir}/%{name} -type d -print0 | xargs -0 chmod 0750
find %{buildroot}/%{_localstatedir}/%{name} -type f -print0 | xargs -0 chmod 0640

install -m 755 -d %{buildroot}/%{_localstatedir}/log/%{name}

%post

%postun
kill -15 `ps -ef | awk '$1~/solr/{print$2}'` 2>/dev/null || /bin/true
sleep 1
getent passwd solr >/dev/null && userdel solr
getent group solr >/dev/null && groupdel solr
rm -fr /home/solr || /bin/true

%files
%attr(-,solr,solr) /opt/%{name}-%{version}/
%attr(-,solr,solr) %{_localstatedir}/%{name}/
%attr(-,solr,solr) %{_localstatedir}/log/%{name}
/opt/%{name}
%{_sysconfdir}/init.d/%{name}
%{_sysconfdir}/default/solr.in.sh

%changelog
* Tue Mar 15 2016 BIS Engineering <justin.cook@digital.bis.gov.uk> - 5.5.0-1
- Initial build for BIS

