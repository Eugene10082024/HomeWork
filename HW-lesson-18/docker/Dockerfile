FROM alpine:3.7

RUN apk update \
&& apk upgrade \ 
&& apk add nginx\ 
&& mkdir -p /run/nginx	

COPY ./default.conf /etc/nginx/conf.d/
COPY ./index.html /usr/share/nginx/html/
	
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

