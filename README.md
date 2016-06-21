# RabbitMQ on Alpine Linux Docker Image #

This image provides RabbitMQ based on Alpine Linux latest stable version. All files are adapted from the original image at [gonkulatorlabs/rabbitmq](https://hub.docker.com/r/gonkulatorlabs/rabbitmq/). Whilst the original image is based on `alpine:3.2` with erlang packages from *edge* repository, this image always based on `alpine:latest` via [bashell/alpine-bash](https://hub.docker.com/r/bashell/alpine-bash/).

### Supported tags and respective Dockerfile links ###

- `latest` ([Dockerfile](https://bitbucket.org/bashell-com/alpine-rmq/src/942c4c97656aa985d20071bcb6907172619af8ec/Dockerfile?fileviewer=file-view-default))
- `3.6.1` ([Dockerfile](https://bitbucket.org/bashell-com/alpine-rmq/src/0460544242770a1b96ed76e86ab95cd4b78e4c5b/Dockerfile?fileviewer=file-view-default))
- `3.6.0` ([Dockerfile](https://bitbucket.org/bashell-com/alpine-rmq/src/ecb866bc1f39dcc4bc44d7aee2ddd78bf76e8a78/Dockerfile?fileviewer=file-view-default))

### Usage ###

The wrapper script starts RabbitMQ (with management plugin enabled), tails the log, and configures listeners on the standard ports:

- `5671/tcp`: Listening port when SSL is enabled
- `5672/tcp`: Non-SSL default listening port
- `15671/tcp`: SSL GUI listening port
- `15672/tcp`: Non-SSL GUI listening port

RabbitMQ's data is persisted to a volume at `/var/lib/rabbitmq`.

To enable SSL set the `SSL_CERT_FILE`, `SSL_KEY_FILE`, and `SSL_CA_FILE` environment variables.  The wrapper script will use the same certs for GUI SSL access as for AMQPS access.

***Examples:***

```bash
# Run without TLS
docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  bashell/alpine-rmq:latest
```

```bash
# Run with TLS enabled
docker run -d \
  --name rabbitmq \
  -p 5671:5671 \
  -p 15671:15671 \
  -e SSL_CERT_FILE=/ssl/cert/cert.pem \
  -e SSL_KEY_FILE=/ssl/cert/key.pem \
  -e SSL_CA_FILE=/ssl/CA/cacert.pem \
  bashell/alpine-rmq:latest
```

### Setting default user and password ###

If you wish to change the default username and password of `guest` / `guest`, you can do so with the `RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS` environmental variables:

```bash
$ docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=user \
  -e RABBITMQ_DEFAULT_PASS=password \
  bashell/alpine-rmq:latest
```

### Customizing ###
To set a custom config, ditch the wrapper script and call `rabbitmq-server` directly.  Place the custom config in `/srv/rabbitmq_server-VERSION/etc/rabbitmq/`.
