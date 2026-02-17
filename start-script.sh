#!/bin/bash
set -e

# Path to the Postgres data directory
PGDATA="/var/lib/postgresql/14/main"

# 1. Ensure the directory exists and has the right permissions for the 'postgres' user
# (Crucial for Proxmox mount points)
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# 2. Initialize Postgres if the directory is empty
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "First run detected: Initializing PostgreSQL database..."
    sudo -u postgres /usr/lib/postgresql/14/bin/initdb -D "$PGDATA"
    
    # Optional: Start PG briefly to create the 'musicbrainz' user/db if needed
    # sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
    # sudo -u postgres psql --command "CREATE USER musicbrainz WITH SUPERUSER PASSWORD 'musicbrainz';"
    # sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D "$PGDATA" -m fast -w stop
fi

# 3. Handle the PID file for Supervisor (prevents 'already running' errors on restart)
rm -f /var/run/supervisord.pid

# 4. Start Supervisor
echo "Starting Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
