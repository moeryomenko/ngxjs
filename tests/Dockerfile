FROM moeryomenko/ngxjs:latest

COPY assets /usr/share/nginx/html
COPY etc /etc

EXPOSE 80
EXPOSE 83

ENTRYPOINT ["nginx", "-g", "daemon off;"]
