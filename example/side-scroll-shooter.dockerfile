FROM node:lts-alpine as build

RUN apk add --no-cache git

WORKDIR src

RUN git clone https://github.com/EremenkoVO/side-scroll-shooter.git . \
    && yarn \
    && yarn run build

FROM moeryomenko/ngxjs:v0.0.2

COPY --from=build /src/dist /usr/share/nginx/html

EXPOSE 80

ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
