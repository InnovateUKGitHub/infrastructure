# The FROM will be replaced when building in OpenShift
FROM rhel7/rhel

MAINTAINER Justin Cook <justin.cook@digital.bis.gov.uk>

# Install headless Java
USER root
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum clean all && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum-config-manager --enable rhel-7-server-extras-rpms && \
    yum-config-manager --enable rhel-server-rhscl-7-beta-rpms && \
    yum-config-manager --enable rhel-7-server-eus-rpms && \
    yum-config-manager --enable rhel-7-server-eus-supplementary-rpms && \
    yum-config-manager --enable rhel-7-server-ose-3.2-rpms && \
    export INSTALL_PKGS="nss_wrapper gettext tar git rh-maven33" && \
    yum clean all && \
    yum install -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    curl -v -j -k -L -o jdk-8u102-linux-x64.rpm \
    -H "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm && \
    rpm -ivh jdk-8u102-linux-x64.rpm && \
    mkdir -p /var/lib/jenkins && \
    echo "export PATH=$PATH:/opt/rh/rh-maven33/root/usr/bin" > /etc/profile.d/maven.sh && \
    chown -R 1001:0 /var/lib/jenkins && \
    chmod -R g+w /var/lib/jenkins

# Copy the entrypoint
COPY configuration/* /var/lib/jenkins/
USER 1001

# Run the JNLP client by default
# To use swarm client, specify "/var/lib/jenkins/run-swarm-client" as Command
ENTRYPOINT ["/var/lib/jenkins/run-jnlp-client"]
