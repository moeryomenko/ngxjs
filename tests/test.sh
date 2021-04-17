#!/bin/sh

DIR=$(dirname "$0")

[ -z $@ ] && host=localhost || host=$@

basic_case () {
	curl http://$host:8080 > $DIR/basic_case.html
	check "basic_case.html"
}

gzip_case () {
	curl -sH 'Accept-encoding: gzip' http://$host:8080 | gunzip - > $DIR/gzip.html
	check "gzip.html"
}

brotli_case () {
	curl -sH 'Accept-encoding: br' http://$host:8080 | brotli --decompress - > $DIR/brotli.html
	check "brotli.html"
}

basic_image_case () {
	curl http://$host:8080/image.jpg > $DIR/image.jpg
	check "image.jpg"
}

gzip_image_case () {
	curl -sH 'Accept-encoding: gzip' http://$host:8080/image.jpg | gunzip - > $DIR/image.jpg
	check "image.jpg"
}

brotli_image_case () {
	curl -sH 'Accept-encoding: br' http://$host:8080/image.jpg | brotli --decompress - > $DIR/image.jpg
	check "image.jpg"
}

check () {
	if [ -z `diff $DIR/$1 $DIR/expected_$1` ]; then
		rm $DIR/$1
		return
	fi

	rm $DIR/$1
	echo -e "\n\e[31mTest" $1 "failed!\e[0m\n"
	exit 1
}

basic_case
gzip_case
brotli_case
basic_image_case
gzip_image_case
brotli_image_case

echo -e "\n\e[32mTests passed!\e[0m\n"
exit 0
