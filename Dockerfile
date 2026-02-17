# 1. Base Image
FROM ubuntu:22.04

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install ALL build-time and run-time dependencies# 1. Stage 1: The "Supplier" (Official MB Postgres Image)
FROM metabrainz/postgres:14 AS builder

# 2. Stage 2: Your "Main" Image
FROM ubuntu:22.04

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (runtime only, no need for heavy build tools anymore)
RUN apt-get update && apt-get install -y \
    supervisor \
    postgresql-14 \
    git \
    curl \
    libdb-dev \
    libicu70 \
    libpq-dev \
    libssl-dev \
    libxml2 \
    python3 \
    nodejs \
    npm \
    cpanminus \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 3. "The Steal": Copy pre-compiled extensions from the builder stage
# These paths are standard for Postgres 14 extensions
COPY --from=builder /usr/lib/postgresql/14/lib/musicbrainz_collate.so /usr/lib/postgresql/14/lib/
COPY --from=builder /usr/lib/postgresql/14/lib/musicbrainz_unaccent.so /usr/lib/postgresql/14/lib/
COPY --from=builder /usr/share/postgresql/14/extension/musicbrainz_collate* /usr/share/postgresql/14/extension/
COPY --from=builder /usr/share/postgresql/14/extension/musicbrainz_unaccent* /usr/share/postgresql/14/extension/

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

# 6. Copy Configs (Ensure start-script.sh and supervisord.conf are in repo root)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh

# 7. Final Prep
RUN chmod +x /usr/local/bin/start-script.sh
EXPOSE 5000 5001 5432

CMD ["/usr/local/bin/start-script.sh"]
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
WORKDIR /src
RUN git clone https://github.com/metabrainz/musicbrainz-docker.git

# Build Collate
WORKDIR /src/musicbrainz-docker/postgres-extension/musicbrainz-collate
# We use || { ... } to catch the error and print the build log before exiting
RUN make clean && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config || { cat /tmp/*.log; exit 1; } && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install

# Build Unaccent
WORKDIR /src/musicbrainz-docker/postgres-extension/musicbrainz-unaccent
RUN make clean && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config install

# 4. Clone and Setup Your Forked Repositories
WORKDIR /app
# Pull MusicBrainz Server
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git musicbrainz-server && \
    cd musicbrainz-server && \
    cpanm --installdeps .

# Pull LM-Bridge
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git lm-bridge && \
    cd lm-bridge && \
    npm install

# 5. Set Environment Variables for Internal Communication
ENV MB_DB_HOST=127.0.0.1
ENV MB_DB_PORT=5432
ENV MB_DB_USER=musicbrainz
ENV MB_DB_PASS=musicbrainz
ENV BRIDGE_PORT=5001

# 6. Copy Configuration Files (Must be in your repo root)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh

# 7. Final Permissions and Port Exposure
RUN chmod +x /usr/local/bin/start-script.sh
EXPOSE 5000 5001 5432

# 8. Set the Startup Entrypoint
CMD ["/usr/local/bin/start-script.sh"]
