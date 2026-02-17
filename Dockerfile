FROM ubuntu:22.04
ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Deps + Postgres 14 + Dev Headers
RUN apt-get update && apt-get install -y \
    supervisor postgresql-14 postgresql-server-dev-14 \
    git curl build-essential libdb-dev libicu-dev libpq-dev \
    nodejs npm cpanminus sudo \
    && rm -rf /var/lib/apt/lists/*

# 2. Build MusicBrainz Postgres Extensions (Required for the DB to work)
WORKDIR /src
RUN git clone https://github.com/metabrainz/musicbrainz-docker.git && \
    cd musicbrainz-docker/postgresql/musicbrainz-collate && make && make install && \
    cd ../musicbrainz-unaccent && make && make install

# 3. Clone your forked repositories
WORKDIR /app
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git musicbrainz-server
RUN git clone https://snorkle256:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git lm-bridge

# 4. Install Application Dependencies
WORKDIR /app/musicbrainz-server
RUN cpanm --installdeps .
WORKDIR /app/lm-bridge
RUN npm install

# 5. Environment Variables for Internal Communication
ENV MB_DB_HOST=127.0.0.1
ENV MB_DB_PORT=5432
ENV MB_DB_USER=musicbrainz
ENV MB_DB_PASS=musicbrainz
ENV BRIDGE_PORT=5001

# 6. Configurations & Entry Script
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

# 7. Exposed Ports
EXPOSE 5000 5001 5432

CMD ["/usr/local/bin/start-script.sh"]
