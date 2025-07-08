#!/bin/bash
set -euo pipefail

# Node Exporter version
VERSION="1.8.1"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz"

echo "Starting Node Exporter installation..."

# Check for root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root!"
  exit 1
fi

# Create node_exporter user if it doesn't exist
if ! id -u node_exporter &>/dev/null; then
  useradd --no-create-home --shell /usr/sbin/nologin node_exporter
  echo "User 'node_exporter' created."
else
  echo "User 'node_exporter' already exists."
fi

# Stop node_exporter if it's already running
if systemctl is-active --quiet node_exporter; then
  echo "Stopping existing node_exporter service..."
  systemctl stop node_exporter
fi

# Download and extract Node Exporter
echo "Downloading Node Exporter $VERSION..."
curl -sL "$URL" -o /tmp/node_exporter.tar.gz
tar -xzf /tmp/node_exporter.tar.gz -C /tmp

# Copy binary and set permissions
echo "Installing binary..."
cp "/tmp/node_exporter-${VERSION}.linux-amd64/node_exporter" /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter
chmod 755 /usr/local/bin/node_exporter

# Create systemd service file
echo "Creating systemd service..."
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
echo "Starting Node Exporter service..."
systemctl daemon-reload
systemctl enable --now node_exporter

echo "Node Exporter installed and running."
echo "Metrics available at: http://$(hostname -I | awk '{print \$1}'):9100/metrics"
