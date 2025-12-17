FROM ghcr.io/astral-sh/uv:0.9.17-bookworm-slim AS builder

# Tenho dúvidas em todas essas variáveis de ambiente. Preciso dos detalhes técnicos
ENV UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy \
  UV_PYTHON_PREFERENCE=only-managed \
  UV_NO_DEV=1 \
  UV_PYTHON_INSTALL_DIR=/python

RUN uv python install 3.14.2 ;

# I WILL REMOVE THESE LINES BELOW. IT IS JUST FOR DEVELOPMENT.
# I CASE I DON'T, YOU MAY DO IT YOUR SELF. IT DOESNT DO ANYTHING
# INTERESTING.
RUN echo "\nset -o vi\nbind -m vi-insert '\"jj\": vi-movement-mode'" >> /root/.bashrc \
  && echo "set show-mode-in-prompt on\nset vi-ins-mode-string " \
    "\"\\e[32m(+)\\e[0m \"\nset vi-cmd-mode-string \"\\e[31m(-)\\e[0m \" \n" \
  >> /root/.inputrc ;


WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project ;

COPY . /app

RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen ;

