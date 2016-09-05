FROM rhel7/rhel

MAINTAINER Justin Cook <justin.cook@digital.bis.gov.uk>

USER root
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum clean all && \
    yum-config-manager --disable rhel-7-server-rt-beta-rpms && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum-config-manager --enable rhel-7-server-extras-rpms && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum-config-manager --enable rhel-7-server-eus-rpms && \
    yum-config-manager --enable rhel-7-server-eus-supplementary-rpms && \
    yum-config-manager --enable rhel-7-server-ose-3.2-rpms && \
    export INSTALL_PKGS="nss_wrapper gettext tar git rh-maven33 unzip" && \
    yum clean all && \
    yum install -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    curl -v -j -k -L -o jdk-8u102-linux-x64.rpm \
    -H "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm && \
    rpm -ivh jdk-8u102-linux-x64.rpm && \
    rm -f /etc/alternatives/java && \
    ln -s /usr/java/jdk1.8.0_102/bin/java /etc/alternatives/java && \
    rm -f jdk-8u102-linux-x64.rpm && \
    curl -s https://get.sdkman.io | bash && \
    source "/root/.sdkman/bin/sdkman-init.sh" && \
    echo -ne '\n' | sdk install gradle 3.0 && \
    mkdir -p /var/lib/jenkins && \
    echo "export PATH=$PATH:/opt/rh/rh-maven33/root/usr/bin" > /etc/profile.d/maven.sh && \
    chown -R 1001:0 /var/lib/jenkins && \
    chmod -R g+w /var/lib/jenkins

COPY configuration/* /var/lib/jenkins/
USER 1001

ENTRYPOINT ["/var/lib/jenkins/run-jnlp-client"]
