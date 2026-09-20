# syntax=docker/dockerfile:1.7

FROM codercom/code-server:4.137.0

USER root

# Install Python and required system packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency and VS Code extension configuration
COPY requirements.txt /tmp/requirements.txt
COPY code-server/extensions.txt /tmp/extensions.txt

# Create Python virtual environment
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --upgrade pip

# Use the virtual environment by default
ENV PATH="/opt/venv/bin:${PATH}"
ENV PYTHONPATH="/opt"

# Make "python" point to the virtual environment
RUN printf '%s\n' \
        '#!/bin/sh' \
        'exec /opt/venv/bin/python "$@"' \
        > /usr/local/bin/python \
    && chmod +x /usr/local/bin/python

# Copy application code
COPY --chown=coder:coder app /opt/app

# Install Python packages from JFrog Artifactory
RUN --mount=type=secret,id=JFROG_USERNAME,required=true \
    --mount=type=secret,id=JFROG_TOKEN,required=true \
    set -eu \
    && JFROG_USERNAME="$(cat /run/secrets/JFROG_USERNAME)" \
    && JFROG_TOKEN="$(cat /run/secrets/JFROG_TOKEN)" \
    && JFROG_USERNAME_ENCODED="$(/usr/bin/python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$JFROG_USERNAME")" \
    && JFROG_TOKEN_ENCODED="$(/usr/bin/python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$JFROG_TOKEN")" \
    && /opt/venv/bin/python -m pip install --no-cache-dir \
        --index-url "https://${JFROG_USERNAME_ENCODED}:${JFROG_TOKEN_ENCODED}@mukti.jfrog.io/artifactory/api/pypi/poc-pypi-virtual/simple/" \
        -r /tmp/requirements.txt

# Install VS Code extensions
USER coder

RUN set -eu; \
    while IFS= read -r extension || [ -n "$extension" ]; do \
        case "$extension" in \
            ""|\#*) \
                ;; \
            *) \
                code-server --install-extension "$extension" \
                ;; \
        esac; \
    done < /tmp/extensions.txt

# Configure application working directory
USER root

WORKDIR /opt/app

USER coder

# VS Code Server port
EXPOSE 8080

# Start VS Code Server
ENTRYPOINT ["code-server"]

CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "password"]
