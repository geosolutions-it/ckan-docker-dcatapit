# ckan-docker-dcatapit

## Deployment diagram

![CKAN compose](https://user-images.githubusercontent.com/717359/138083856-24f209ab-28a4-4cb9-90da-ff5f48db5367.png)

## Build and composition

To debug the composition locally please add `CKAN_HOST` value to `/etc/hosts` with `127.0.0.1` ip address, by default the host is `ckan`.
Once you checkout the project run these command inside its path:

```Shell

cp .env-sample .env
docker-compose build
docker-compose up -d

```

## Run composition in production

Edit `.env` file and change `COMPOSE_PROFILES=dev` to `COMPOSE_PROFILES=prod` in order to enable `proxy` service then run:

```Shell

docker-compose up -d

```

Without editing `.env`:

```Shell

docker-compose --profile prod up -d

```
