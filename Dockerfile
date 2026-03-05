FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    ca-certificates \
    openssl \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest

WORKDIR /root

COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/root/start.sh"]