# Ambiente Docker + uv (FastAPI dev)

Ambiente de desenvolvimento com Python 3.14.2 gerenciado pelo `uv`, pensado para
demonstrar build multi-stage e fluxo de trabalho com Docker Compose. O serviço
Postgres é opcional e não é usado pelo app de exemplo.

## Requisitos

- Docker e Docker Compose
- `env/.env` (não versionado). Exemplo:
  ```
  POSTGRES_USER=postgres
  POSTGRES_PASSWORD=your_password
  POSTGRES_DB=db_name
  PGDATA=/var/lib/postgresql/18/docker
  ```

## Estrutura do projeto

- `Dockerfile`: estágio `builder` instala Python 3.14.2 via uv e resolve deps;
  estágio `development` copia `/python` + projeto, cria usuário `python`
  (uid 1000) e ativa `.venv`. Entrypoint roda `uvicorn` em `0:8000`.
- `compose.yaml`: serviço `dockeryt` (porta 8000) e serviço opcional `psql`
  (Postgres 18) com healthcheck e volume em `./_data/postgresql`.
  `develop.watch` sincroniza código e reinicia o container; mudanças em
  `uv.lock` disparam rebuild.
- `Justfile`: atalhos para `docker`, `docker compose` e `uv`.
- `src/dockeryt/main.py`: rota simples `/` com FastAPI.

## Primeira execução (manual)

```sh
docker compose --env-file env/.env -f compose.yaml up --build --watch
# A API ficará em http://localhost:8000/
```

## Usando Just

- Subir e rebuildar: `just dccup --build -d` (adicione `--env-file env/.env` se
  quiser)
- Entrar no container: `just dcexec /bin/bash`
- Parar/limpar: `just dccdown`

## Hot reload / watch

- `develop.watch` sincroniza alterações do diretório para `/app` e reinicia o
  container quando arquivos mudam.
- Quando `uv.lock` muda, o Compose faz rebuild da imagem (garante deps
  atualizadas).

## Sobre o Postgres (opcional)

- O app não consome o banco; é apenas exemplo de serviço extra.
- Se não precisar: remova `depends_on` do serviço `dockeryt` e o serviço `psql`
  do `compose.yaml`.
