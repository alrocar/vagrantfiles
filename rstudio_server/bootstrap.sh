#!/bin/bash

sudo apt-get update -y

sudo apt-get install r-base -y
sudo apt-get install gdebi-core -y
wget https://download2.rstudio.org/rstudio-server-0.99.903-amd64.deb
sudo gdebi rstudio-server-0.99.903-amd64.deb -n

cat <<EOF > /etc/init.d/rstudio-server.sh
#!/bin/sh
### BEGIN INIT INFO
# Provides:          rstudio-server
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start RStudio server
# Description:       Start RStudio server
### END INIT INFO
set -e
case "\$1" in
start)
    rstudio-server start
    ;;
stop)
	rstudio-server stop
	;;
restart|reload|force-reload)
	rstudio-server restart
    ;;
esac
exit 0
EOF

# start on boot
chmod +x /etc/init.d/rstudio-server.sh
sudo update-rc.d rstudio-server.sh defaults

/etc/init.d/rstudio-server.sh start