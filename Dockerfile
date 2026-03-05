FROM node:22-bookworm-slim

# Install tools for agents + runtime basics
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

# Install OpenClaw globally via npm
RUN npm install -g openclaw@latest

WORKDIR /root

# Persist OpenClaw state (configs, sessions, WhatsApp auth, etc.)
VOLUME ["/root/.openclaw"]

# Copy startup script
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# Use an init system so signals are handled cleanly (important on PaaS)
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/root/start.sh"]