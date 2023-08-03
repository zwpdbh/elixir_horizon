# Use Livebook as Super REPL

## Description

We could start our mix project with a naming node and connect to it using Livebook. \
This enable use to use Livebook as a super REPL.

## Start Mix project with naming node

```sh
iex --name elixir_horizion@localhost --cookie some_token -S mix
Erlang/OTP 25 [erts-13.2] [source] [64-bit] [smp:24:24] [ds:24:24:10] [async-threads:1] [jit:ns]

Interactive Elixir (1.14.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(elixir_horizion@localhost)1> Node.self
:elixir_horizion@localhost
```

- `--name` specify we running node using full name mode.
  - `:"elixir_horizion@localhost"` is the node name.
  - There is also a `--sname` short name option.
- `--cookie` is the shared token for all connecting nodes. Here is `some_token`.

## Start Livebook using Container image

```sh
docker run \
--network=host \
-e LIVEBOOK_DISTRIBUTION=name \
-e LIVEBOOK_COOKIE=some_token \
-e LIVEBOOK_NODE=livebook@localhost \
-u $(id -u):$(id -g) \
-v $(pwd):/data \
ghcr.io/livebook-dev/livebook:0.8.1
```

- `--network` specify the docker container we run use [Host network driver](https://docs.docker.com/network/drivers/host/).
- Those LIVEBOOK options are from [Livebook README](https://github.com/livebook-dev/livebook).
- Tag `0.8.1` from Livebook image support OTP25.
- If succeed, it should oupt something like:

  ```sh
  [Livebook] Application running at http://0.0.0.0:8080/?token=gwc234cmrxsfnqkaeeu6hv7wjhg3qe2g
  ```

## Connect to the node from Livebook

- Create or open a Livebook.
- Go to

  - Runtime settings
  - Configure
    - `Name` should be: `elixir_horizion@localhost`
    - `Cookie` should be: the cookie we used above, such as `some_token`.
  - If connect succeed, it should shows the reconnect and disconnect option along with memory metric for the connect node.

- If connected, it means we could create code block and execute any code as if we are using `iex`.

## Summary

- What is a node \
  In the context of distributed systems and Erlang/Elixir, a "node" refers to an individual running instance of the Erlang or Elixir runtime environment. Each node is a separate process or application instance that can communicate with other nodes in the same distributed system.

- `--sname` vs `--name` option
  - When using `--sname`, the node name is restricted to the local host only.
  - When using `--name`, you can set an arbitrary node name that is not restricted to a single host.

## Troubleshooting

- Evaluator.IOProxy module into the remote node, potentially due to Erlang/OTP version mismatch.
  - We have to make sure the Livebook's OTP version is compatibe with connecting node's OTP version.
- docker: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?.
  - On ubuntu (WSL), remember to start Docker service by: `sudo service docker start`.
- Livebook docker image could start without problem, but could not visit its address from windows 11.
  
  From my experience, it is caused by I started the docker in WSL2 while the docker engine is using is Docker desktop in windows 11.
  - uninstall docker desktop from windows 11 
  - [install docker in Ubuntu20.04](https://docs.docker.com/engine/install/ubuntu/)
  - Start livebook docker as before, you should click and visit Livebook from that address now.