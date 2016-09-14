#!/bin/sh

# install docker
curl -s https://raw.githubusercontent.com/alrocar/vagrantfiles/master/install-docker.sh | bash

# swagger editor
docker pull swaggerapi/swagger-editor
docker run -d --name swagger-editor -p 8080:8080 swaggerapi/swagger-editor

# swagger ui
wget https://github.com/swagger-api/swagger-ui/archive/v2.2.3.tar.gz
tar xvzf v2.2.3.tar.gz
cd swagger-ui-2.2.3
docker build -t swagger-ui-builder .
docker run -d --name swagger-ui -p 8081:8080 swagger-ui-builder

# init script
cat <<EOF > /etc/init.d/start-swagger.sh
#!/bin/sh
set -e

case "\$1" in
start)
    docker start swagger-editor
    cd ~/swagger-ui-2.2.3
    docker start swagger-ui
    ;;
stop|restart|reload|force-reload)
    ;;
esac
exit 0
EOF

# start on boot
chmod +x /etc/init.d/start-swagger.sh
sudo update-rc.d start-swagger.sh defaults 10