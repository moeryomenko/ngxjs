# Accept the Go version for the image to be set as a build argument.
# Default to Go 1.12.
ARG GO_VERSION=1.12

FROM golang:${GO_VERSION}-alpine as build

LABEL maintainer="Maxim Eryomenko <moeryomenko@gmail.com>"

ENV NGINX_VERSION 1.17.5
ENV NJS_VERSION 0.3.2
ENV CFLAGS "-O3"
ENV CXXFLAGS "-O3"

RUN apk add --no-cache \
    gcc libc-dev autoconf libtool automake \
    make cmake ninja pcre-dev zlib-dev \
    linux-headers libxslt-dev gd-dev geoip-dev \
    perl-dev libedit-dev git alpine-sdk findutils \
    libunwind-dev curl tar

WORKDIR /src

# Build BoringSSL.
RUN git clone https://boringssl.googlesource.com/boringssl \
    && cd boringssl \
    && mkdir build \
    && cd build \
    && cmake -GNinja .. \
    && ninja \
    && mkdir -p ../.openssl/lib \
    && cd ../.openssl \
    && ln -s ../include include \
    && cp ../build/crypto/libcrypto.a lib/ \
    && cp ../build/ssl/libssl.a  lib/ \
    && cd /src

# Download njs module.
RUN mkdir njs \
    && curl -SL http://hg.nginx.org/njs/archive/${NJS_VERSION}.tar.gz | tar xz -C njs --strip-components=1

# Download ngx_brotli nginx module for support Brotli compression.
RUN git clone --recurse-submodules https://github.com/google/ngx_brotli.git

ENV NGX_BROTLI_STATIC_MODULE_ONLY 1
ENV CFLAGS "-static -static-libgcc -ldl -O3 -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"

# Build static binary nginx with BoringSSL instead OpenSSL
RUN mkdir nginx \
    && curl -SL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz -C nginx --strip-components=1 \
    && cd nginx \
    && ./configure --prefix=/usr/share/nginx \
	               --sbin-path=/usr/bin/nginx \
                   --conf-path=/etc/nginx/nginx.conf \
                   --error-log-path=/var/log/nginx/error.log \
                   --http-log-path=/var/log/nginx/access.log \
                   --lock-path=/run/lock/subsys/nginx \
                   --user=1000 \
                   --group=1000 \
                   --with-threads \
                   --with-file-aio \
                   --with-http_geoip_module \
                   --with-http_gzip_static_module \
                   --with-http_ssl_module \
                   --with-http_v2_module \
                   --with-http_realip_module \
                   --with-http_gunzip_module \
                   --with-http_gzip_static_module \
                   --with-http_slice_module \
                   --with-http_stub_status_module \
                   --without-select_module \
                   --without-poll_module \
                   --add-module="/src/njs/nginx" \
                   --add-module="/src/ngx_brotli" \
                   --with-openssl="/src/boringssl" \
                   --with-cc-opt="-I /src/boringssl/.openssl/include/" \
                   --with-ld-opt="-static -Wl,-Bsymbolic-functions -Wl,-z,relro -L /src/boringssl/.openssl/lib/" \
                   --with-cpu-opt=generic \
    && touch "/src/boringssl/.openssl/include/openssl/ssl.h" \
    && make && make install

# Create the user and group files that will be used in the running container to
# run the process as an unprivileged user.
RUN mkdir /user \
    && echo '1000:x:65534:65534:1000:/:' > /user/passwd \
    && echo '1000:x:65534:' > /user/group

# Final stage: the running container.
FROM scratch

# # Import the user and group files from the build stage.
COPY --from=build /user/group /user/passwd /etc/
# Import the Certificate-Authority certificates for enabling HTTPS.
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Import related nginx files.
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/bin/nginx /usr/bin/nginx
COPY --from=build /usr/share/nginx /usr/share/nginx
COPY --from=build /var/log/nginx /var/log/nginx

EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/nginx", "-g", "daemon off;"]
