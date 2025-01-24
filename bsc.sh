#work in progress. here the snapshot size is 3tb and first have to download which gets downlaoded in multiple parts and then have 
#to extract all in sam one file for which to make it will take time as first have to download and see names etc and since we later 
#would not be actually downloading the snapshot, wold be using some other process to spin up faset, so no need to put effort on 
#this as we would not be using these steps of downloading snapshot so it would be time waste

#!/bin/bash

# Update and install necessary packages
apt update -y
apt install aria2 wget curl unzip vim -y

# Download the snapshot fetch script
wget https://raw.githubusercontent.com/bnb-chain/bsc-snapshots/main/dist/fetch-snapshot.sh

# Download & checksum the mainnet snapshot (replace with the correct snapshot if necessary)
bash fetch-snapshot.sh -d -c -D /data mainnet-geth-pbss-20250104

# Extract the downloaded snapshot
bash fetch-snapshot.sh -e -D /data -E /data mainnet-geth-pbss-20250104

# Download the latest geth binary
wget $(curl -s https://api.github.com/repos/bnb-chain/bsc/releases/latest | grep browser_ | grep geth_linux | cut -d\" -f4)
mv geth_linux geth
chmod +x geth

# Download the mainnet zip file (adjust the URL as needed)
wget $(curl -s https://api.github.com/repos/bnb-chain/bsc/releases/latest | grep browser_ | grep mainnet | cut -d\" -f4)
unzip mainnet.zip

# Create the systemd service file
cat <<EOF > /etc/systemd/system/bsc.service
[Unit]
Description=BSC Services
After=network.target

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=16384
ExecStart=/usr/local/bin/geth --config /data/config.toml --datadir /data/server/data-seed --cache 8000 --rpc.allow-unprotected-txs --history.transactions 0 --tries-verify-mode none --http.vhosts="*" --metrics --metrics.influxdb.endpoint "http://10.20.20.44:8086" --metrics.influxdb.username "geth" --metrics.influxdb.password "chosenpassword" --pprof --pprof.addr 0.0.0.0 --pprof.port 6060 --metrics.influxdb.database "mainnet-bsc-3"
KillMode=process
Restart=on-failure
RestartSec=2
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
systemctl daemon-reload

# Start and enable the BSC service
systemctl start bsc.service
systemctl enable bsc.service

echo "BSC Node installation and setup complete. The service is now running."
