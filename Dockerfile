FROM ghcr.io/astral-sh/uv:0.9.17-trixie-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy \
  UV_PYTHON_PREFERENCE=only-managed \
  UV_NO_DEV=1 \
  UV_PYTHON_INSTALL_DIR=/python

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* ;

RUN uv python install 3.14.2 ;

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project ;

COPY . /app

RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen ;

################################################################################

FROM debian:trixie-slim AS development

ENV PYTHONUNBUFFERED=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* ;

# Cria grupo e user 1000 (padrão Linux)
# Define shell bash (pra você não entrar no container com sh capado)
# Cria a home (pro cache do uv/pip funcionar)
RUN groupadd --gid 1000 python \
  && useradd --uid 1000 --gid python --shell /bin/bash --create-home python ;

# I WILL REMOVE THESE LINES BELOW. IT IS JUST FOR DEVELOPMENT.
# IN CASE I DON'T, YOU MAY DO IT YOUR SELF. IT DOESNT DO ANYTHING
# INTERESTING.
RUN echo "\nset -o vi\nbind -m vi-insert '\"jj\": vi-movement-mode'" | tee \
  /root/.bashrc /home/python/.bashrc 2>/dev/null \
  && echo 'set show-mode-in-prompt on\nset vi-ins-mode-string "+) " ' \
  '\nset vi-cmd-mode-string "-) " ' | tee /root/.inputrc /home/python/.inputrc 2>/dev/null ;

COPY --from=builder --chown=python:python /python /python
COPY --from=builder --chown=python:python /app /app

ENV PATH="/app/.venv/bin:${PATH}"

USER python
ENTRYPOINT []
WORKDIR /app

CMD ["uvicorn", "--host", "0", "--port", "8000", "src.dockeryt.main:app"]
