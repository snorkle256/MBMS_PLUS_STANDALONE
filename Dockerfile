# 1. Base Image - Official Perl 5.38 (Debian-based)
FROM perl:5.38

ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install System Dependencies 
# (Added libgnutls28-dev and gnupg for the GnuPG module)
RUN apt-get update && apt-get install -y \
    supervisor \
    postgresql-14 \
    postgresql-server-dev-14 \
    git curl build-essential pkg-config \
    libdb-dev libicu-dev libpq-dev libssl-dev libxml2-dev \
    libgnutls28-dev gnupg \
    nodejs npm sudo \
    && rm -rf /var/lib/apt/lists/*

# 3. Build MusicBrainz Postgres Extensions
WORKDIR /src
RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-collate.git && \
    cd postgresql-musicbrainz-collate && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git && \
    cd postgresql-musicbrainz-unaccent && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

# 4. Clone and Setup Your Forked Repositories
WORKDIR /app
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git && \
    cd musicbrainz-server && \
    cpanm --installdeps .

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git && \
    cd LM-Bridge && \
    npm install

# 5. Environment & Scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

EXPOSE 5000 5001 5432
CMD ["/usr/local/bin/start-script.sh"]
