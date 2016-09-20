#!/bin/bash

sudo apt-get update -y
sudo apt-get install python-pip python-dev build-essential -y
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
pip install --upgrade pip
pip install jupyter

cat <<EOF > /etc/init.d/start-jupyter-notebook.sh
#!/bin/sh
### BEGIN INIT INFO
# Provides:          start-jupyter-notebook
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start jupyter notebook
# Description:       Start jupyter notebook
### END INIT INFO
set -e
case "\$1" in
start)
    jupyter notebook --notebook-dir=/vagrant --no-browser --ip=0.0.0.0 &
    ;;
stop|restart|reload|force-reload)
    ;;
esac
exit 0
EOF

# start on boot
chmod +x /etc/init.d/start-jupyter-notebook.sh
sudo update-rc.d start-jupyter-notebook.sh defaults

/etc/init.d/start-jupyter-notebook.sh start
