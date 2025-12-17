# Configs
set unstable

# Load .env
set dotenv-load := true
set dotenv-path := "env/.env"

# Docker
dc_container_name := "dockeryt"
dc_image_name := "dockeryt"
dc_dockerfile_path := "Dockerfile"
dc_compose_path := "compose.yaml"

# Python
python_version := "3.14"

# Just list all recipes
[group('Just')]
default:
  @just -l

# uv run {{ ARGS }}. E.g. just run python -VV
[group('Run')]
@run *ARGS:
  uv run {{ ARGS }}

# uv sync {{ ARGS }}. E.g. just sync --all-pacages --no-install-project
[group('Setup')]
[no-cd]
@sync *ARGS:
  uv sync {{ ARGS }}

# uv init {{ ARGS }}. E.g. just init --name="nice" --description=\"That's nice!\"
[group('Setup')]
[no-cd]
init *ARGS:
  uv init --package {{ ARGS }}

# docker (alias). E.g just dc ps -a
[group('Docker')]
@dc *ARGS:
  docker {{ ARGS }}

# docker compose (alias). E.g just dcc up -d
[group('Docker')]
@dcc *ARGS:
  docker compose -f {{dc_compose_path}} {{ARGS}}

# build the image using the Dockerfile in dc_dockerfile_path.
[group('Docker')]
@dcbuild:
  docker build -t {{dc_container_name}} -f {{dc_dockerfile_path}} .

# start the container in {{ dc_container_name }}
[group('Docker')]
@dcstart:
  docker start {{dc_container_name}}

# docker compose -f {{ dc_compose_path }} up {{ ARGS }}
[group('Docker')]
@dccup *ARGS:
  -docker compose -f {{dc_compose_path}} up {{ARGS}}

# docker compose -f {{ dc_compose_path }} down {{ ARGS }}
[group('Docker')]
@dccdown *ARGS:
  docker compose -f {{dc_compose_path}} down {{ARGS}}

# docker compose -f {{ dc_compose_path }} up --build {{ ARGS }}
[group('Docker')]
@dccbuild *ARGS:
  -just dccup --build {{ARGS}}

@_dcexec *ARGS:
  just dcstart
  docker exec -it {{dc_container_name}} {{ARGS}}

# It will build and start the container if it does not exit
[group('Docker')]
@dcexec *ARGS:
  if test -z $(docker container ls -q -a --filter name={{ dc_container_name }}); then \
    just dcbuild ; \
    just dccup -d ; \
    just _dcexec {{ ARGS }} ; \
  else \
    just _dcexec {{ ARGS }} ; \
  fi

@_dcrun *ARGS:
  docker run --rm -it {{dc_image_name}} {{ARGS}}

# It will build the image if it does not exit
[group('Docker')]
@dcrun *ARGS:
  if test -z $(docker image ls -q {{ dc_image_name }}); then \
    just dcbuild ; \
    just _dcrun {{ ARGS }} ; \
  else \
    just _dcrun {{ ARGS }} ; \
  fi

# this will stop all containers, delete the image and container
[group('Docker')]
[confirm]
@dcnuke:
  echo docker stop $(docker ps -q -a)
  -docker stop $(docker ps -q -a) > /dev/null 2>&1 || true

  echo docker rmi {{dc_image_name}}
  -docker rmi {{dc_image_name}} > /dev/null 2>&1 || true

  echo docker rm {{dc_container_name}}
  -docker rm {{dc_container_name}} > /dev/null 2>&1 || true
