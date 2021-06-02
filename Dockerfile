# Accept the Go version for the image to be set as a build argument.
# Default to Go 1.16.
ARG GO_VERSION=1.16

FROM golang:${GO_VERSION}-alpine as build

LABEL maintainer="Maxim Eryomenko <moeryomenko@gmail.com>"

ENV NGINX_VERSION 1.21.0
ENV NJS_VERSION 0.5.3
ENV CFLAGS "-O2"
ENV CXXFLAGS "-O2"

RUN apk add --no-cache \
    gcc libc-dev autoconf libtool automake \
    make cmake ninja pcre-dev \
    linux-headers libxslt-dev gd-dev geoip-dev \
    perl-dev libedit-dev git alpine-sdk findutils \
    libunwind-dev curl tar

WORKDIR /src

RUN git clone --depth 1 --branch 2.0.1 https://github.com/zlib-ng/zlib-ng.git \
    && cd zlib-ng \
    && cmake . \
    && cmake -DZLIB_COMPAT=ON -DZLIB_ENABLE_TESTS=OFF --build . -DCMAKE_BUILD_TYPE=Release \
    && cmake --build . --target install

# Build BoringSSL.
RUN git clone https://boringssl.googlesource.com/boringssl \
    && cd boringssl \
    && mkdir build \
    && cd build \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release .. \
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
                   --without-http_access_module \
                   --without-http_auth_basic_module \
                   --without-http_autoindex_module \
                   --without-http_browser_module \
                   --without-http_charset_module \
                   --without-http_empty_gif_module \
                   --without-http_geo_module \
                   --without-http_memcached_module \
                   --without-http_map_module \
                   --without-http_ssi_module \
                   --without-http_split_clients_module \
                   --without-http_fastcgi_module \
                   --without-http_uwsgi_module \
                   --without-http_userid_module \
                   --without-http_scgi_module \
                   --without-mail_pop3_module \
                   --without-mail_imap_module \
                   --without-mail_smtp_module \
                   --add-module="/src/njs/nginx" \
                   --add-module="/src/ngx_brotli" \
                   --with-openssl="/src/boringssl" \
                   --with-cc-opt="-I /src/boringssl/.openssl/include/" \
                   --with-ld-opt="-static -Wl,-Bsymbolic-functions -Wl,-z,relro -L /src/boringssl/.openssl/lib/" \
                   --with-cpu-opt=generic \
    && touch "/src/boringssl/.openssl/include/openssl/ssl.h" \
    && make && make install

# NOTE: fix problems with poman: no items matching glob.
RUN touch /var/log/nginx/error.log \
    && touch /var/log/nginx/access.log

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
COPY --from=build /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=build /usr/bin/nginx /usr/bin/nginx
COPY --from=build /usr/share/nginx /usr/share/nginx
COPY --from=build /var/log/nginx /var/log/nginx
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

STOPSIGNAL SIGQUIT

ENTRYPOINT ["/usr/bin/nginx", "-g", "daemon off;"]
