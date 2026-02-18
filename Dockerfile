# 1. Base Image
FROM ubuntu:22.04

# Pass the PAT during build
ARG GITHUB_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# 2. Dependencies (Postgres 14, Perl, Python, Node)
RUN apt-get update && apt-get install -y \
    supervisor postgresql-14 postgresql-server-dev-14 \
    git curl build-essential pkg-config libdb-dev libicu-dev \
    libpq-dev libssl-dev libxml2-dev python3 python3-pip \
    nodejs npm cpanminus sudo \
    && rm -rf /var/lib/apt/lists/*

# 3. Build MusicBrainz Postgres Extensions (Public Repos)
WORKDIR /src
RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-collate.git && \
    cd postgresql-musicbrainz-collate && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

RUN git clone --depth 1 https://github.com/metabrainz/postgresql-musicbrainz-unaccent.git && \
    cd postgresql-musicbrainz-unaccent && \
    make PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config with_llvm=no install

# 4. Clone Your Private Forks (Using x-access-token for the PAT)
WORKDIR /app
RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/musicbrainz-server.git && \
    cd musicbrainz-server && cpanm --installdeps .

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/snorkle256/LM-Bridge.git && \
    cd LM-Bridge && npm install

# 5. Clone Search Indexer (Public - Recommended for search functionality)
RUN git clone --depth 1 https://github.com/metabrainz/sir.git && \
    cd sir && pip3 install -r requirements.txt

# 6. Final Setup
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-script.sh /usr/local/bin/start-script.sh
RUN chmod +x /usr/local/bin/start-script.sh

EXPOSE 5000 5001 5432
CMD ["/usr/local/bin/start-script.sh"]
