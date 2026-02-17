# 1. Base Image
FROM ubuntu:24.04

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install all dependencies (Postgres 16 is default in Ubuntu 24.04)
RUN apt-get update && apt-get install -y \
    supervisor \
    postgresql-16 \
    postgresql-server-dev-16 \
    git \
    curl \
    build-essential \
    pkg-config \
    libdb-dev \
    libicu-dev \
    icu-devtools \
    libpq-dev \
    libssl-dev \
    libxml2-dev \
    python3 \
    nodejs \
    npm \
    cpanminus \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 3. Build MusicBrainz Postgres Extensions
WORKDIR /src
RUN git clone --depth 1 https://github.com/metabrainz/musicbrainz-docker.git

# Dynamically find and build Collate
RUN export COLLATE_DIR=$(find /src/musicbrainz-docker -name "musicbrainz-collate" -type d | head -n 1) && \
    cd "$COLLATE_DIR" && \
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config install

# Dynamically find and build Unaccent
RUN export UNACCENT_DIR=$(find /src/musicbrainz-docker -name "musicbrainz-unaccent" -type d | head -n 1) && \
    cd "$UNACCENT_DIR" && \
    make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config install

# 4. Clone and Setup Your Forked Repositories
WORKDIR /app
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && \
    cpanm --installdeps .

RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git lm-bridge && \
    cd lm-bridge && \
    npm install

# 5. Environment Variables
ENV MB_DB_HOST=127.0.0.1
ENV MB_DB_PORT=5432
ENV BRIDGE_PORT=5001

# 6. Copy Configs
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh

# 7. Final Prep
RUN chmod +x /usr/local/bin/start-script.sh
EXPOSE 5000 5001 5432

CMD ["/usr/local/bin/start-script.sh"]
