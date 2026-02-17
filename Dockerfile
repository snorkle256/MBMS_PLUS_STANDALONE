# 1. Base Image
FROM ubuntu:22.04

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install EVERYTHING needed for building C extensions and Perl deps
RUN apt-get update && apt-get install -y \
    supervisor \
    postgresql-14 \
    postgresql-server-dev-14 \
    git \
    curl \
    build-essential \
    pkg-config \
    libdb-dev \
    libicu-dev \
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
# We use 'mkdir -p /src' to be safe and verify directory existence
WORKDIR /src
RUN git clone https://github.com/metabrainz/musicbrainz-docker.git && \
    cd musicbrainz-docker/postgresql/musicbrainz-collate && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install && \
    cd ../musicbrainz-unaccent && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install && \
    cd / && rm -rf /src/musicbrainz-docker

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
ENV MB_DB_USER=musicbrainz
ENV MB_DB_PASS=musicbrainz
ENV BRIDGE_PORT=5001

# 6. Copy Configs (Must be in your repo root)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh

# 7. Final Prep
RUN chmod +x /usr/local/bin/start-script.sh
EXPOSE 5000 5001 5432

CMD ["/usr/local/bin/start-script.sh"]
