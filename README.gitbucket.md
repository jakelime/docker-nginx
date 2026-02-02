# Docker builder for Nginx to Gitbucket

Builds nginx docker instance.

This is designed to be a git submodule to be used as part of the docker-compose method.

The nginx service is meant to be a in the web layer, serving as a Load Balancer and
provide reverse-proxy service to the backend application layers and/or database layer.

This deployments uses self-signed HTTPS certificate. The builder script will generate
a self-signed certificate for deployment.

## Quickstart

1. Referring to `.env.example`, create `.env`.
1. Run `bash ./generate_certs.sh`
1. That's it for submodule setup.
1. Go up to `./docker-compose.yml` root and run `docker compose up` from there.

## Folder Structure

```text
.[docker-compose root dir]
├── src-nginx/
│   ├── certs/ # (this will be created by build script)
|   |   ├── nginx.crt
│   │   └── nginx.key
│   ├── templates/
│   │   └── default.conf.template # (refer to official docs, envsubst using nginx-docker-image's templates)
│   └── Dockerfile
|
├── src-pgdb/ # PostgresDB
│   └── ...
|
├── src-gitbucket/
|   ├── .env.docker
|   └── Dockerfile
|
├── .env
└── readme.md
```

## Example docker-compose.yml

```yaml
services:
  nginx:
    restart: unless-stopped
    container_name: ${PROJECT_NAME}_nginx
    build:
      context: ./src-nginx
      args:
        url_docker: ${url_docker_index}
    environment:
      - NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
      - NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
      - NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d
      - SHARED_DATA_DIR=${SHARED_DATA_DIR}
      - NGINX_LOG_FOLDER=${SHARED_LOGS_DIR}/nginx/
      - NGINX_STATIC_FOLDER=${SHARED_DATA_DIR}/www/static/
      - NGINX_MEDIA_FOLDER=${SHARED_DATA_DIR}/www/media/
      - NGINX_PORT_HTTP=${NGINX_PORT_HTTP}
      - NGINX_PORT_HTTPS=${NGINX_PORT_HTTPS}
      - GITBUCKET_PORT=${GITBUCKET_PORT}
      - GITBUCKET_PREFIX=${GITBUCKET_PREFIX}
    ports:
      - "${NGINX_PORT_HTTP}:${NGINX_PORT_HTTP}"
      - "${NGINX_PORT_HTTPS}:${NGINX_PORT_HTTPS}"
    volumes:
      - ./src-nginx/templates:/etc/nginx/templates
      - datashare:/datashare
      - appcache_nginx:/var/cache/nginx
    networks:
      - appnet

  pgdb:
    container_name: ${PROJECT_NAME}_pgdb
    restart: unless-stopped
    env_file:
      - ./src-pgdb/.env.docker
    build:
      context: ./src-pgdb
      args:
        url_docker: ${url_docker_index}
    ports:
      - "$PGDB_PORT:$PGDB_PORT"
    command:
      - postgres
      - "-p"
      - ${PGDB_PORT}
    volumes:
      - dbdata_pgdb:/var/lib/postgresql/data
    networks:
      - appnet

  gitbucket:
    restart: unless-stopped
    environment:
      - GITBUCKET_DB_URL=jdbc:postgresql://pgdb:${PGDB_PORT}/gitbucket
      - GITBUCKET_DB_DRIVER=org.postgresql.Driver
      - GITBUCKET_PORT=${GITBUCKET_PORT}
      - GITBUCKET_PREFIX=${GITBUCKET_PREFIX}
    container_name: ${PROJECT_NAME}_gitbucket
    build:
      context: ./src-gitbucket
      args:
        url_docker: ${url_docker_index}
    env_file:
      - ./src-gitbucket/.env.docker
    volumes:
      - data_gitbucket:/gitbucket
    ports:
      - "${GITBUCKET_PORT}:${GITBUCKET_PORT}"
    networks:
      - appnet

networks:
  appnet:

volumes:
  datashare:
  data_gitbucket:
  dbdata_pgdb:
  applogs:
  appcache_nginx:
```

## Script for self-generated SSL certs

```bash
#!/bin/bash

certs_dir="./certs"

mkdir -p $certs_dir
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $certs_dir/nginx.key -out $certs_dir/nginx.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
echo "Certificates generated in $certs_dir/"
```
