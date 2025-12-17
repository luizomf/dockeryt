# Passos para configurar o Docker

Primeiro, vamos construir a nossa imagem. O `uv` tem vários tipos de imagens
para usos específicos, a que vamos usar será para gerar uma imagem builder. A
responsabilidade desta imagem não será o objetivo final, ela só será usada como
um "builder" que vai configurar todo o ambiente. Depois, a nossa imagem final só
precisará copiar os dados que precisar dela.

Este será o nosso `Dockerfile`.

```dockerfile
from ghcr.sh/astral-sh/uv:0.9.17-bookwork-slim as builder

ENV UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy \
  UV_PYTHON_PREFERENCE=only-managed \
  UV_NO_DEV=1 \
  UV_PYTHON_INSTALL_DIR=/python

RUN uv python install 3.14.2

WORKDIR=/app
```

---
