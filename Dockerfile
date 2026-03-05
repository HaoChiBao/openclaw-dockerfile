FROM node:22-bookworm-slim

# Install tools for agents (git, curl, wget, python, etc.)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally via npm
RUN npm install -g openclaw@latest

WORKDIR /root

# Copy startup script
COPY start.sh /root/
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]
