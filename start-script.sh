#!/bin/bash
set -e

# Path to the Postgres 14 data directory
PGDATA="/var/lib/postgresql/14/main"

# 1. Ensure the directory exists and has the right permissions
# This is crucial for Proxmox Bind Mounts to work without 'Permission Denied'
mkdir -p "$PGDATA"
chown -R postgres:postgres /var/lib/postgresql/
chmod 700 "$PGDATA"

# 2. Initialize Postgres if the directory is empty
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "First run detected: Initializing PostgreSQL 14 database..."
    sudo -u postgres /usr/lib/postgresql/14/bin/initdb -D "$PGDATA"
fi

# 3. Clean up any stale PID files (prevents startup loops)
rm -f /var/run/supervisord.pid

# 4. Start Supervisor
echo "Starting Supervisor to manage MusicBrainz Services..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
