#!/bin/sh

# https://www.elastic.co/guide/en/beats/libbeat/current/beats-reference.html

# update and install required packages
sudo apt-get update -y
sudo apt-get install unzip openjdk-7-jre -y

INSTALL_DIR=/opt/elk
mkdir -p $INSTALL_DIR

# install ElasticSearch
# https://www.elastic.co/guide/en/beats/libbeat/current/elasticsearch-installation.html
cd $INSTALL_DIR
curl -L -O https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-2.3.3.deb
sudo dpkg -i elasticsearch-2.3.3.deb
sudo /etc/init.d/elasticsearch start &

# install logstash and filebeat plugin
# https://www.elastic.co/guide/en/beats/libbeat/current/logstash-installation.html
cd $INSTALL_DIR
curl -L -O https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb
sudo dpkg -i logstash_2.3.2-1_all.deb
cd /opt/logstash
sudo ./bin/logstash-plugin install logstash-input-beats

sudo cat <<EOF > /etc/logstash/conf.d/logstash.conf
input {
  beats {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => "localhost:9200"
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF

sudo /etc/init.d/logstash start &

# install Kibana
# https://www.elastic.co/guide/en/beats/libbeat/current/kibana-installation.html
cd $INSTALL_DIR
#curl -L -O https://download.elastic.co/kibana/kibana/kibana-4.5.1-linux-x64.tar.gz
#tar xzvf kibana-4.5.1-linux-x64.tar.gz
#cd kibana-4.5.1-linux-x64/bin
#sudo ./kibana &
curl https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | sudo tee -a /etc/apt/sources.list.d/kibana-4.4.x.list
sudo apt-get update -y
sudo apt-get -y install kibana
sudo update-rc.d kibana defaults 96 9
sudo service kibana start


# loading the beats dashboards
# https://www.elastic.co/guide/en/beats/libbeat/current/load-kibana-dashboards.html
cd $INSTALL_DIR
curl -L -O http://download.elastic.co/beats/dashboards/beats-dashboards-1.2.3.zip
unzip beats-dashboards-1.2.3.zip
cd beats-dashboards-1.2.3/
./load.sh

# install beats
# https://www.elastic.co/guide/en/beats/libbeat/current/installing-beats.html
cd $INSTALL_DIR
echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
sudo apt-get update -y && sudo apt-get install filebeat -y
sudo rm -f /etc/filebeat/filebeat.yml
sudo cat <<EOF > /etc/filebeat/filebeat.yml
filebeat:
  prospectors:
    -
      paths:
        - /var/log/*.log
      input_type: log

  registry_file: /var/lib/filebeat/registry

output:

  logstash:
    hosts: ["localhost:5044"]

shipper:
logging:

  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
curl -XPUT 'http://localhost:9200/_template/filebeat' -d@/etc/filebeat/filebeat.template.json
sudo /etc/init.d/filebeat restart &

# install topbeat
# https://www.elastic.co/guide/en/beats/topbeat/1.2/topbeat-getting-started.html
cd $INSTALL_DIR
curl -L -O https://download.elastic.co/beats/topbeat/topbeat_1.2.3_amd64.deb
sudo dpkg -i topbeat_1.2.3_amd64.deb
sudo rm -f /etc/topbeat/topbeat.yml
sudo cat <<EOF > /etc/topbeat/topbeat.yml
input:
  period: 10
  procs: [".*"]
output:
  logstash:
    hosts: ["127.0.0.1:5044"]

    # Optional load balance the events between the Logstash hosts
    #loadbalance: true
EOF
curl -XPUT 'http://localhost:9200/_template/topbeat' -d@/etc/topbeat/topbeat.template.json
sudo /etc/init.d/topbeat start &

# install packetbeat
# https://www.elastic.co/guide/en/beats/packetbeat/current/packetbeat-overview.html
cd $INSTALL_DIR
sudo apt-get install libpcap0.8
curl -L -O https://download.elastic.co/beats/packetbeat/packetbeat_1.2.3_amd64.deb
sudo dpkg -i packetbeat_1.2.3_amd64.deb
sudo rm -f /etc/packetbeat/packetbeat.yml
sudo cat <<EOF > /etc/packetbeat/packetbeat.yml
interfaces:
  device: any
protocols:
  dns:
    ports: [53]

    include_authorities: true
    include_additionals: true

  http:
    ports: [80]

  #memcache:
    #ports: [11211]

  #mysql:
    #ports: [3306]

  pgsql:
    ports: [5432]

  #redis:
    #ports: [6379]

  #thrift:
    #ports: [9090]

  #mongodb:
    #ports: [27017]
output:
  logstash:
    hosts: ["127.0.0.1:5044"]
EOF
curl -XPUT 'http://localhost:9200/_template/packetbeat' -d@/etc/packetbeat/packetbeat.template.json
sudo /etc/init.d/packetbeat start &