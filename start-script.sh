#!/bin/bash
set -e

PGDATA="/var/lib/postgresql/16/main"
PGCONFIG="/etc/postgresql/16/main"

# 1. Fix Permissions
mkdir -p "$PGDATA"
chown -R postgres:postgres /var/lib/postgresql/
chmod 700 "$PGDATA"

# 2. Initialize PostgreSQL 16
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "First run: Initializing PostgreSQL 16..."
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D "$PGDATA"
    
    if [ ! -f "$PGCONFIG/postgresql.conf" ]; then
        mkdir -p "$PGCONFIG"
        cp /usr/share/postgresql/16/postgresql.conf.sample "$PGCONFIG/postgresql.conf"
        chown -R postgres:postgres "$PGCONFIG"
    fi
fi

# 3. Cleanup and Launch
rm -f /var/run/supervisord.pid
echo "Launching Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
