#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2015 Microsoft Azure
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Trent Swanson (Full Scale 180 Inc)
#
help()
{
    echo "This script installs kibana on a dedicated VM in the elasticsearch ARM template cluster"
    echo "Parameters:"
    echo "-n elasticsearch cluster name"
    echo "-v elasticsearch version 1.5.0"

    echo "-l install plugins true/false"
    echo "-S kibana server password"

    echo "-h view this help content"
}

#hit the loadbalancers internal IP
ELASTICSEARCH_URL="http://10.0.1.100:9200"

#Script Parameters
CLUSTER_NAME="elasticsearch"
ES_VERSION="2.0.0"
INSTALL_PLUGINS=0

USER_KIBANA4_SERVER_PWD="changeME"

#Loop through options passed
while getopts :n:v:S:lh optname; do
  log "Option $optname set with value ${OPTARG}"
  case $optname in
    n) #set cluster name
      CLUSTER_NAME=${OPTARG}
      ;;
    v) #elasticsearch version number
      ES_VERSION=${OPTARG}
      ;;
    S) #shield kibana server pwd
      USER_KIBANA4_SERVER_PWD=${OPTARG}
      ;;
    l) #install plugins
      INSTALL_PLUGINS=1
      ;;
    h) #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

# Install Oracle Java
install_java()
{
    log "Installing Java"
    add-apt-repository -y ppa:webupd8team/java
    apt-get -y update  > /dev/null
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
    apt-get -y install oracle-java8-installer 

    log "Installed Java"
}

sudo groupadd -g 999 kibana
sudo useradd -u 999 -g 999 kibana

sudo mkdir -p /opt/kibana
curl -o kibana.tar.gz https://download.elastic.co/kibana/kibana/kibana-4.2.0-linux-x64.tar.gz
tar xvf kibana.tar.gz -C /opt/kibana/ --strip-components=1

sudo chown -R kibana: /opt/kibana

# set the elasticsearch URL
mv /opt/kibana/config/kibana.yml /opt/kibana/config/kibana.yml.bak
echo "elasticsearch.url: \"$ELASTICSEARCH_URL\"" >> /opt/kibana/config/kibana.yml
if [ ${INSTALL_PLUGINS} -ne 0 ]; then
    echo "elasticsearch.username: es_kibana_server" >> /opt/kibana/config/kibana.yml
    echo "elasticsearch.password: \"$USER_KIBANA4_SERVER_PWD\"" >> /opt/kibana/config/kibana.yml
fi

# install the marvel plugin
/opt/kibana/bin/kibana plugin --install elasticsearch/marvel/latest
# install the sense plugin (but only if the template user also chose to install shield)
if [ ${INSTALL_PLUGINS} -ne 0 ]; then
    /opt/kibana/bin/kibana plugin --install elastic/sense
fi

# Add upstart task and start kibana service
cat << EOF > /etc/init/kibana.conf
# kibana
description "Elasticsearch Kibana Service"

start on starting
script
    /opt/kibana/bin/kibana
end script
EOF

chmod +x /etc/init/kibana.conf
sudo service kibana start
