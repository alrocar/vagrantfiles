# deps
sudo apt-get update -y
sudo apt-get install apt-transport-https ca-certificates git unzip -y
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y

# install docker
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo touch /etc/apt/sources.list.d/docker.list
echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' | sudo tee --append /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get purge lxc-docker
apt-cache policy docker-engine

# configure and start docker
sudo apt-get install docker-engine -y
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker vagrant
sudo systemctl enable docker

# install docker-compose
sudo -i
curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# download fiware-orion
ORION_VERSION=1.3.0
ORION_DIR=fiware-orion-$ORION_VERSION

wget https://github.com/telefonicaid/fiware-orion/archive/$ORION_VERSION.zip
unzip $ORION_VERSION.zip -d .

# start fiware-orion docker container
cd $ORION_DIR/docker
sudo docker-compose up -d

# smoke test
# curl --write-out "%{http_code}\n" --silent --output /dev/null "http://localhost:1026/version"
curl "http://localhost:1026/version"

# start accumulator (optional)
#sudo apt-get -y install python-pip
#curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
#sudo python get-pip.py
#sudo pip install Flask
#cd ~/$ORION_DIR/scripts
#./accumulator-server.py --port 1028 --url /accumulate --host ::1 --pretty-print -v