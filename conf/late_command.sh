cp conf/pcc/bash_profile /target/home/pcc/.bash_profile
in-target chown pcc:pcc /home/pcc/.bash_profile
cp conf/etc/apt/sources.list /target/etc/apt/sources.list
cp conf/etc/openbox/rc.xml.patch /target/tmp
in-target patch /etc/xdg/openbox/rc.xml -i /tmp/rc.xml.patch
cp -R conf/.config /target/home/pcc/
in-target chown -R pcc:pcc /home/pcc/.config
mkdir -p /target/etc/mosquitto
cp conf/etc/mosquitto/mosquitto.conf /target/etc/mosquitto/
cp conf/pcc/pcc.sh /target/home/pcc/
in-target chown pcc:pcc /home/pcc/pcc.sh
wget -q -P /target/tmp https://www.mongodb.org/static/pgp/server-6.0.asc
in-target apt-key add /tmp/server-6.0.asc
cp conf/etc/apt/sources.list.d/mongodb-org-6.0.list /target/etc/apt/sources.list.d/mongodb-org-6.0.list
in-target curl -sL https://deb.nodesource.com/setup_16.x > /target/tmp/setup.sh
chmod +x /target/tmp/setup.sh
/target/tmp/setup.sh
wget -P /target/tmp wget https://downloads.mongodb.com/compass/mongodb-compass_1.28.1_amd64.deb
in-target apt-get update
in-target apt-get install -y nodejs mongodb-org /tmp/mongodb-compass_1.28.1_amd64.deb
in-target systemctl enable mongod
