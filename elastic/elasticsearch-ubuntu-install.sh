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
# Modified - 7-15-15, 8-3-15 Chad Pryor
### Remaining work items
### -Alternate discovery options (Azure Storage)
### -Implement Idempotency and Configuration Change Support
### -Implement OS Disk Striping Option (Currently using multiple Elasticsearch data paths)
### -Implement Non-Durable Option (Put data on resource disk)
### -Configure Work/Log Paths
### -Recovery Settings (These can be changed via API)
### -Add shield user/password
### -Add logic for marvel only/monitoring cluster
### -Add Marvel configs - marvel.agent.exporter.es.hosts: ["es-mon-1:9200","es-mon-2:9200"]
### -Add more config - http.cors.enabled: true | http.cors.allow-origin: /.*/ | http.cors.allow-credentials: true
### -Add role based configs or link to file source - CLUSTER_TYPE. Need to add to parameters and extend logic
### -Issue with KOPF and 1.6.2+

# Modified Martijn Laarman
### resynced with azure-quick-start
### 2.0 changes reflectect

help()
{
    echo "This script installs Elasticsearch cluster on Ubuntu"
    echo "Parameters:"
    echo "-n elasticsearch cluster name"
    echo "-v elasticsearch version 1.5.0"

    echo "-d cluster uses dedicated masters"
    echo "-Z <number of nodes> hint to the install script how many data nodes we are provisioning"

    echo "-l install plugins true/false"
    echo "-a shield admin"
    echo "-A admin password"
    echo "-r shield read only"
    echo "-R read password"
    echo "-k shield kibana"
    echo "-K kibana password"

    echo "-x configure as a dedicated master node"
    echo "-y configure as client only node (no master, no data)"
    echo "-z configure as data node (no master)"

    echo "-m marvel host , used for agent config"

    echo "-h view this help content"
}

# Log method to control/redirect log output
log()
{
    # If you want to enable this logging add a un-comment the line below and add your account id
    #curl -X POST -H "content-type:text/plain" --data-binary "${HOSTNAME} - $1" https://logs-01.loggly.com/inputs/<key>/tag/es-extension,${HOSTNAME}
    echo "$1"
}

log "Begin execution of Elasticsearch script extension on ${HOSTNAME}"

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

# TEMP FIX - Re-evaluate and remove when possible
# This is an interim fix for hostname resolution in current VM
grep -q "${HOSTNAME}" /etc/hosts
if [ $? == 0 ]
then
  echo "${HOSTNAME}found in /etc/hosts"
else
  echo "${HOSTNAME} not found in /etc/hosts"
  # Append it to the hsots file if not there
  echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
  log "hostname ${HOSTNAME} added to /etchosts"
fi

#Script Parameters
CLUSTER_NAME="elasticsearch"
ES_VERSION="2.0.0"
INSTALL_PLUGINS="true" #We use this because of ARM template limitation
CLIENT_ONLY_NODE=0
DATA_NODE=0
MASTER_ONLY_NODE=0
USER_ADMIN="es_admin"
USER_ADMIN_PWD="changeME"
USER_READ="es_read"
USER_READ_PWD="changeME"
USER_KIBANA4="es_kibana4"
USER_KIBANA4_PWD="changeME"
MARVEL_HOST='"marvel_export:marvelPassw0rd@10.1.0.10:9200","marvel_export:marvelPassw0rd@10.1.0.11:9200","marvel_export:marvelPassw0rd@10.1.0.12:9200"'
CLUSTER_USES_DEDICATED_MASTERS=0
DATANODE_COUNT=0

MINIMUM_MASTER_NODES=3
UNICAST_HOSTS='["masterVm0:3200","masterVm1:9300","masterVm2:9300"]'

#Loop through options passed
while getopts :n:v:l:a:A:r:R:k:K:m:Z:xyzdh optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    n) #set cluster name
      CLUSTER_NAME=${OPTARG}
      ;;
    v) #elasticsearch version number
      ES_VERSION=${OPTARG}
      ;;
    l) #install plugins
      INSTALL_PLUGINS=${OPTARG}
      ;;
    a) #add shield admin
      USER_ADMIN=${OPTARG}
      ;;
    A) #shield admin pwd
      USER_ADMIN_PWD=${OPTARG}
      ;;
    r) #add shield user
      USER_READ=${OPTARG}
      ;;
    R) #shield admin pwd
      USER_READ_PWD=${OPTARG}
      ;;
    k) #add shield kibana4
      USER_KIBANA=${OPTARG}
      ;;
    K) #shield admin pwd
      USER_ADMIN_PWD=${OPTARG}
      ;;
    m) #marvel host
      MARVEL_HOST=${OPTARG}
      ;;
    x) #master node
      MASTER_ONLY_NODE=1
      ;;
    y) #client node
      CLIENT_ONLY_NODE=1
      ;;
    z) #client node
      DATA_NODE=1
      ;;
    Z) #number of data nodes hints (used to calculate minimum master nodes)
      DATANODE_COUNT=${OPTARG}
      ;;
    d) #cluster is using dedicated master nodes
      CLUSTER_USES_DEDICATED_MASTERS=1
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

if [ ${CLUSTER_USES_DEDICATED_MASTERS} -ne 0 ]; then
    MINIMUM_MASTER_NODES=3
    UNICAST_HOSTS='["masterVm0:9300","masterVm1:9300","masterVm2:3200"]'
else 
    MINIMUM_MASTER_NODES=$(((DATANODE_COUNT/2)+1))
    UNICAST_HOSTS='['
    for i in $(seq 0 $((DATANODE_COUNT-1))); do
        UNICAST_HOSTS="$UNICAST_HOSTS\"esdatavm$i:3200\","
    done
    UNICAST_HOSTS="${UNICAST_HOSTS%?}]"
fi

log "Bootstrapping cluster '$CLUSTER_NAME' with minimum_master_nodes set to $MINIMUM_MASTER_NODES"
log "Cluster uses dedicated master nodes is set to $CLUSTER_USES_DEDICATED_MASTERS and unicast goes to $UNICAST_HOSTS"

# Base path for data disk mount points
# The script assume format /datadisks/disk1 /datadisks/disk2
DATA_BASE="/datadisks"

# Configure Elasticsearch Data Disk Folder and Permissions
setup_data_disk()
{
    log "Configuring disk $1/elasticsearch/data"

    mkdir -p "$1/elasticsearch/data"
    chown -R elasticsearch:elasticsearch "$1/elasticsearch"
    chmod 755 "$1/elasticsearch"
}

# Install Oracle Java
install_java()
{
    log "Installing Java"
    add-apt-repository -y ppa:webupd8team/java
    apt-get -y update  > /dev/null
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
    apt-get -y install oracle-java8-installer  > /dev/null
}

# Install Elasticsearch
install_es()
{

	# Elasticsearch 2.0.0 uses a different download path
    if [[ "${ES_VERSION}" == \2* ]]; then
        DOWNLOAD_URL="https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/$ES_VERSION/elasticsearch-$ES_VERSION.deb"
    else
        DOWNLOAD_URL="https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ES_VERSION.deb"
    fi

    log "Installing Elaticsearch Version - $ES_VERSION"
	log "Download location - $DOWNLOAD_URL"
    sudo wget -q "$DOWNLOAD_URL" -O elasticsearch.deb
    sudo dpkg -i elasticsearch.deb
}

# Primary Install Tasks
#########################
#NOTE: These first three could be changed to run in parallel
#      Future enhancement - (export the functions and use background/wait to run in parallel)

#Format data disks (Find data disks then partition, format, and mount them as seperate drives)
# using the -s paramater causing disks under /datadisks/* to be raid0'ed
#------------------------
bash vm-disk-utils-0.1.sh -s

#Install Oracle Java
#------------------------
install_java

#
#Install Elasticsearch
#-----------------------
install_es

# Prepare configuration information
# Configure permissions on data disks for elasticsearch user:group
#--------------------------
RAIDDISK="/datadisks/disk1"
DATAPATH_CONFIG="/datadisks/disk1/elasticsearch/data"

setup_data_disk ${RAIDDISK}

#if [ -d "${DATA_BASE}" ]; then
#    for D in `find /datadisks/ -mindepth 1 -maxdepth 1 -type d`
#    do
#        #Configure disk permissions and folder for storage
#        setup_data_disk ${D}
#        # Add to list for elasticsearch configuration
#        DATAPATH_CONFIG+="$D/elasticsearch/data,"
#    done
#    #Remove the extra trailing comma
#    DATAPATH_CONFIG="${DATAPATH_CONFIG%?}"
#else
#    #If we do not find folders/disks in our data disk mount directory then use the defaults
#    log "Configured data directory does not exist for ${HOSTNAME} using defaults"
#fi

#Configure Elasticsearch settings
#---------------------------
#Backup the current Elasticsearch configuration file
mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.bak

# Set cluster and machine names - just use hostname for our node.name
echo "cluster.name: $CLUSTER_NAME" >> /etc/elasticsearch/elasticsearch.yml
echo "node.name: ${HOSTNAME}" >> /etc/elasticsearch/elasticsearch.yml

# Configure paths - if we have data disks attached then use them
if [ -n "$DATAPATH_CONFIG" ]; then
    log "Update configuration with data path list of $DATAPATH_CONFIG"
    echo "path.data: $DATAPATH_CONFIG" >> /etc/elasticsearch/elasticsearch.yml
fi

# Configure discovery
log "Update configuration with hosts configuration of $UNICAST_HOSTS"
echo "discovery.zen.ping.multicast.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
echo "discovery.zen.ping.unicast.hosts: $UNICAST_HOSTS" >> /etc/elasticsearch/elasticsearch.yml


# Configure Elasticsearch node type
log "Configure master/client/data node type flags master-$MASTER_ONLY_NODE data-$DATA_NODE"

if [ ${MASTER_ONLY_NODE} -ne 0 ]; then
    log "Configure node as master only"
    echo "node.master: true" >> /etc/elasticsearch/elasticsearch.yml
    echo "node.data: false" >> /etc/elasticsearch/elasticsearch.yml
    # echo "marvel.agent.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
elif [ ${DATA_NODE} -ne 0 ]; then
    log "Configure node as data only"
    echo "node.master: false" >> /etc/elasticsearch/elasticsearch.yml
    echo "node.data: true" >> /etc/elasticsearch/elasticsearch.yml
    # echo "marvel.agent.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
elif [ ${CLIENT_ONLY_NODE} -ne 0 ]; then
    log "Configure node as data only"
    echo "node.master: false" >> /etc/elasticsearch/elasticsearch.yml
    echo "node.data: false" >> /etc/elasticsearch/elasticsearch.yml
    # echo "marvel.agent.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
else
    log "Configure node for master and data"
    echo "node.master: true" >> /etc/elasticsearch/elasticsearch.yml
    echo "node.data: true" >> /etc/elasticsearch/elasticsearch.yml
fi

echo "discovery.zen.minimum_master_nodes: $MINIMUM_MASTER_NODES" >> /etc/elasticsearch/elasticsearch.yml
echo "network.host: _non_loopback_" >> /etc/elasticsearch/elasticsearch.yml
#echo "bootstrap.mlockall: true" >> /etc/elasticsearch/elasticsearch.yml

# DNS Retry
echo "options timeout:1 attempts:5" >> /etc/resolvconf/resolv.conf.d/head
resolvconf -u

# Increase maximum mmap count
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf

#"action.disable_delete_all_indices: ${DISABLE_DELETE_ALL}" >> /etc/elasticsearch/elasticsearch.yml
#"action.auto_create_index: ${AUTOCREATE_INDEX}" >> /etc/elasticsearch/elasticsearch.yml

# Configure Environment
#----------------------
#/etc/default/elasticseach
#Update HEAP Size in this configuration or in upstart service
#Set Elasticsearch heap size to 50% of system memory
#TODO: Move this to an init.d script so we can handle instance size increases
ES_HEAP=`free -m |grep Mem | awk '{if ($2/2 >31744)  print 31744;else print $2/2;}'`
log "Configure elasticsearch heap size - $ES_HEAP"
echo "ES_HEAP_SIZE=${ES_HEAP}m" >> /etc/default/elasticsearch

#Optionally Install Marvel
log "Plugin install set to ${INSTALL_PLUGINS}"
if [ "${INSTALL_PLUGINS}" == "true" ]; then
    log "Installing Plugins Shield, Marvel, Watcher"
    sudo /usr/share/elasticsearch/bin/plugin install elasticsearch/license/latest
    sudo /usr/share/elasticsearch/bin/plugin install elasticsearch/shield/latest
    sudo /usr/share/elasticsearch/bin/plugin install elasticsearch/wa/tcher/latest
    sudo /usr/share/elasticsearch/bin/plugin install marvel-agent

	#should not be necessary and should use -Des.path.conf see:
	# https://www.elastic.co/guide/en/shield/shield-1.3/installing-shield.html
	#
	#sudo cp -r /usr/share/elasticsearch/config/shield /etc/elasticsearch/

	log " finished plugin install"
    log " Start Adding Shield Users ${USER_ADMIN}"
    log " Start adding ${USER_ADMIN}"
    sudo /usr/share/elasticsearch/bin/shield/esusers useradd "${USER_ADMIN}" -p "${USER_ADMIN_PWD}" -r admin
    log " Finished adding ${USER_ADMIN}"

	log " Start adding ${USER_READ}"
    sudo /usr/share/elasticsearch/bin/shield/esusers useradd "${USER_READ}" -p "${USER_READ_PWD}" -r user
    log " Finished adding ${USER_READ}"

	log " Start adding ${USER_KIBANA4}"
    sudo /usr/share/elasticsearch/bin/shield/esusers useradd "${USER_KIBANA4}" -p "${USER_KIBANA4_PWD}" -r kibana4
    log " Finished adding ${USER_KIBANA4}"

	log " adding marvel_agent "
	sudo /usr/share/elasticsearch/bin/shield/esusers useradd marvel_export -p marvelPassw0rd -r marvel_agent
    log " finished adding Shield Users"
    log "Finished Plugin install and shield users"


	echo "marvel.agent.exporter.es.hosts: [ $MARVEL_HOST ]" >> /etc/elasticsearch/elasticsearch.yml
	echo "marvel.agent.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
fi


#Install Monit
#TODO - Install Monit to monitor the process (Although load balancer probes can accomplish this)

#and... start the service
log "Starting Elasticsearch on ${HOSTNAME}"
update-rc.d elasticsearch defaults 95 10
sudo service elasticsearch start
log "complete elasticsearch setup and started"
exit 0

#Script Extras

#Configure open file and memory limits
#Swap is disabled by default in Ubuntu Azure VMs
#echo "bootstrap.mlockall: true" >> /etc/elasticsearch/elasticsearch.yml

# Verify this is necessary on azure
#echo "elasticsearch     -    nofile    65536" >> /etc/security/limits.conf
#echo "elasticsearch     -    memlock   unlimited" >> /etc/security/limits.conf
#echo "session    required    pam_limits.so" >> /etc/pam.d/su
#echo "session    required    pam_limits.so" >> /etc/pam.d/common-session
#echo "session    required    pam_limits.so" >> /etc/pam.d/common-session-noninteractive
#echo "session    required    pam_limits.so" >> /etc/pam.d/sudo

#--------------- TEMP (We will use this for the update path yet) ---------------
#Updating the properties in the existing configuraiton has been a bit sensitve and requires more testing
#sed -i -e "/cluster\.name/s/^#//g;s/^\(cluster\.name\s*:\s*\).*\$/\1${CLUSTER_NAME}/" /etc/elasticsearch/elasticsearch.yml
#sed -i -e "/bootstrap\.mlockall/s/^#//g;s/^\(bootstrap\.mlockall\s*:\s*\).*\$/\1true/" /etc/elasticsearch/elasticsearch.yml
#sed -i -e "/path\.data/s/^#//g;s/^\(path\.data\s*:\s*\).*\$/\1${DATAPATH_CONFIG}/" /etc/elasticsearch/elasticsearch.yml

# Minimum master nodes nodes/2+1 (These can be configured via API as well - (_cluster/settings))
# gateway.expected_nodes: 10
# gateway.recover_after_time: 5m
#----------------------
