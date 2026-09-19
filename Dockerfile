FROM codercom/code-server:4.137.0

USER root

RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-venv curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
COPY code-server/extensions.txt /tmp/extensions.txt

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip

ENV PATH="/opt/venv/bin:$PATH"

COPY app /opt/app

RUN python3 -m pip install --no-cache-dir -r /tmp/requirements.txt

RUN while read extension; do \
      code-server --install-extension "$extension"; \
    done < /tmp/extensions.txt

WORKDIR /opt/app

USER coder

EXPOSE 8080

ENTRYPOINT ["code-server"]

CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "password"]