#!/bin/sh

sudo apt-get update
sudo apt-get install aptitude -y

# install supervisor
sudo aptitude install supervisor -y

# install sample app
cat <<EOF > /tmp/hello.sh
#!/bin/sh

c=1
while true; do echo 'hello $c!'; sleep 2; (( c++ )); done

EOF

chmod +x /tmp/hello.sh
mkdir -p /var/log/hello

# configure supervisor
cat <<EOF > /etc/supervisor/conf.d/hello.conf
[program:hello]
command=/tmp/hello.sh
directory=/tmp
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/hello/hello.err.log
stdout_logfile=/var/log/hello/hello.out.log
user=vagrant
environment=OH_MY='world'
EOF

# configure admin console
echo "[inet_http_server] 
port = 9001 
username = admin 
password = admin"|cat - /etc/supervisor/supervisord.conf > /tmp/out && sudo mv /tmp/out /etc/supervisor/supervisord.conf

# this fixes a problem with the tail log feature in the web admin console
# https://github.com/Supervisor/supervisor/pull/195
sudo sed -i "s/request.push(tail_f_producer(request, logfile, 1024))/request.push(tail_f_producer(request, logfile, 1024).more())/g" /usr/share/pyshared/supervisor/http.py

# apply changes
sudo service supervisor stop
sudo service supervisor start