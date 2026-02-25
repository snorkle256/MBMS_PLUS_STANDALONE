FROM perl:5.38

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install PG16 and build tools
RUN apt-get update && apt-get install -y curl ca-certificates gnupg lsb-release && \
    curl -fSsL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y \
    supervisor postgresql-16 postgresql-server-dev-16 \
    git build-essential pkg-config libdb-dev libicu-dev \
    libpq-dev libssl-dev libxml2-dev libgnutls28-dev gnupg \
    nodejs npm sudo && rm -rf /var/lib/apt/lists/*


# 2. Build Collate
WORKDIR /src
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/postgresql-musicbrainz-collate.git && \
    cd postgresql-musicbrainz-collate && \
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config clean && \
    # Passing variables as arguments to make is the most reliable method
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config \
         PG_CPPFLAGS="-I/usr/include/postgresql/16/server" \
         with_llvm=no install

# 3. Build Unaccent
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/postgresql-musicbrainz-unaccent.git && \
    cd postgresql-musicbrainz-unaccent && \
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config clean && \
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config \
         PG_CPPFLAGS="-I/usr/include/postgresql/16/server" \
         with_llvm=no install
    
# 4. Main App Setup
WORKDIR /app
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git && \
    cd musicbrainz-server && cpanm --installdeps .

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git && \
    cd LM-Bridge && npm install

# 5. Configs
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

EXPOSE 5000 5001 5432
CMD ["/usr/local/bin/start-script.sh"]
