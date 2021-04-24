# Build and run examples

## Side scroll shooter

```sh
$ docker build -f side-scroll-shooter.dockerfile -t side-scroll-shooter:v0.0.1 .
$ docker run -p 8080:80 side-scroll-shooter:v0.0.1
```

## TLSv1.3

For simple example you can use self-signed cert, like as in
https://blog.amosti.net/local-reverse-proxy-with-nginx-mkcert-and-docker-compose/

nginx configuration:
```nginx.conf
...
    server {
        listen      80;
        listen      [::]:80;
        listen      83 ssl;
        listen      [::]:83 ssl;
        server_name localhost;

        ssl_certificate     /etc/nginx/localhost+2.pem;
        ssl_certificate_key /etc/nginx/localhost+2-key.pem;
        ssl_protocols       TLSv1.3;
		...
    }
...
```

```docker
FROM moeryomenko/ngxjs:latest

# also can copy assets or static files.

COPY localhost+2.pem /etc/nginx
COPY localhost+2-key.pem /etc/nginx
COPY nginx.conf /etc/nginx

EXPOSE 80 83

ENTRYPOINT ["nginx", "-g", "daemon off;"]
```
