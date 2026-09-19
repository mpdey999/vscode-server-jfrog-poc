# syntax=docker/dockerfile:1.7

FROM codercom/code-server:4.137.0

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
COPY code-server/extensions.txt /tmp/extensions.txt

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONPATH="/opt"

RUN ln -sf /opt/venv/bin/python /usr/local/bin/python

COPY app /opt/app

# Build with:
# docker buildx build \
#   --secret id=JFROG_USERNAME,env=JFROG_USERNAME \
#   --secret id=JFROG_TOKEN,env=JFROG_TOKEN \
#   -t code-server-python .

RUN --mount=type=secret,id=JFROG_USERNAME,required=true \
    --mount=type=secret,id=JFROG_TOKEN,required=true \
    set -eu; \
    JFROG_USERNAME="$(cat /run/secrets/JFROG_USERNAME)"; \
    JFROG_TOKEN="$(cat /run/secrets/JFROG_TOKEN)"; \
    JFROG_USERNAME_ENCODED="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$JFROG_USERNAME")"; \
    JFROG_TOKEN_ENCODED="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$JFROG_TOKEN")"; \
    python3 -m pip install --no-cache-dir \
        --index-url "https://${JFROG_USERNAME_ENCODED}:${JFROG_TOKEN_ENCODED}@mukti.jfrog.io/artifactory/api/pypi/poc-pypi-virtual/simple/" \
        -r /tmp/requirements.txt

USER coder

RUN set -eu; \
    while IFS= read -r extension || [ -n "$extension" ]; do \
        case "$extension" in \
            ""|\#*) ;; \
            *) code-server --install-extension "$extension" ;; \
        esac; \
    done < /tmp/extensions.txt

USER root

WORKDIR /opt/app

USER coder

EXPOSE 8080

ENTRYPOINT ["code-server"]

CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "password"]