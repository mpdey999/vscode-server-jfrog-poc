# syntax=docker/dockerfile:1.7

# Pin by digest for supply-chain reproducibility, e.g.
# FROM codercom/code-server:4.137.0@sha256:<digest>
FROM codercom/code-server:4.137.0

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
COPY code-server/extensions.txt /tmp/extensions.txt

RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/python -m pip install --no-cache-dir --upgrade pip

ENV PATH="/opt/venv/bin:$PATH"

RUN ln -s /opt/venv/bin/python /usr/local/bin/python

ENV PYTHONPATH="/opt"

# coder must own its working tree, otherwise code-server can't write to it
COPY --chown=coder:coder app /opt/app

# Secrets are mounted, never copied into a layer. Do NOT add `set -x` here:
# it would print the JFrog token straight into the build log.
RUN --mount=type=secret,id=JFROG_USERNAME \
    --mount=type=secret,id=JFROG_TOKEN \
    set -eu; \
    JFROG_USERNAME="$(cat /run/secrets/JFROG_USERNAME)"; \
    JFROG_TOKEN="$(cat /run/secrets/JFROG_TOKEN)"; \
    JFROG_USERNAME_ENCODED="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$JFROG_USERNAME")"; \
    pip install --no-cache-dir \
      --index-url "https://${JFROG_USERNAME_ENCODED}:${JFROG_TOKEN}@mukti.jfrog.io/artifactory/api/pypi/poc-pypi-virtual/simple/" \
      -r /tmp/requirements.txt; \
    rm -f /tmp/requirements.txt

USER coder

# `set -e` is required: a bare `while` loop returns only the status of the
# LAST command, so a failed extension install would otherwise pass silently.
RUN set -eu; \
    while IFS= read -r extension || [ -n "$extension" ]; do \
      [ -z "$extension" ] && continue; \
      code-server --install-extension "$extension"; \
    done < /tmp/extensions.txt

WORKDIR /opt/app

EXPOSE 8080

ENTRYPOINT ["code-server"]
CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "password"]