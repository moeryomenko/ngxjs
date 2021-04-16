# ngxjs
This nginx container with support modules njs and Brotli, also use BoringSSL instead OpenSSL.

## Testing

```bash
$ docker run -p 8080:80 ngxjs:v0.0.2
$ ./tests/test.sh

Test passed!
```

## Usage

In your Dockerfile just use in `FROM` directive and `COPY` your assets to `/usr/share/nginx/html` folder.
Also you can change default `nginx.conf` just replace by `COPY` your config to `/etc/nginx/nginx.conf`.

```Dockerfile
FROM moeryomenko/ngxjs:latest

COPY assets /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf


EXPOSE 80

ENTRYPOINT [ "nginx", "-g", "daemon off" ]
```

For more information see examples.

## Examples

Contains into `./examples`

## TODO

* add more examples
* add more tests (because nginx and all components are compiled from source code)
