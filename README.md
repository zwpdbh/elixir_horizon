# Use Livebook as Super REPL

## Start Mix project with naming node

```sh
iex --name hello@127.0.0.1 --cookie some_token -S mix
```

## Start Livebook using Container image

```sh
sudo docker run \
--network=host \
-e LIVEBOOK_DISTRIBUTION=name \
-e LIVEBOOK_COOKIE=some_token \
-e LIVEBOOK_NODE=livebook@localhost \
-e LIVEBOOK_PORT=8007 \
-e LIVEBOOK_IFRAME_PORT=8008 \
-e RELEASE_NODE=livebook_hello \
-u $(id -u):$(id -g) \
-v $(pwd):/data \
ghcr.io/livebook-dev/livebook:0.12.1
```

