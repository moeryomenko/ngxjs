#!/bin/sh

DIR=$(dirname "$0")

[ -z $@ ] && host=localhost || host=$@

basic_case () {
	curl http://$host:8080 > $DIR/basic_case.html
	check "basic_case"
}

gzip_case () {
	curl -sH 'Accept-encoding: gzip' http://$host:8080 | gunzip - > $DIR/gzip.html
	check "gzip"
}

brotli_case () {
	curl -sH 'Accept-encoding: br' http://$host:8080 | brotli --decompress - > $DIR/brotli.html
	check "brotli"
}

check () {
	if [ -z `diff $DIR/$1.html $DIR/expected_$1.html` ]; then
		rm $DIR/$1.html
		return
	fi

	rm $DIR/$1.html
	echo -e "\n\e[31mTest" $1 "failed!\e[0m\n"
	exit 1
}

basic_case
gzip_case
brotli_case

echo -e "\n\e[32mTests passed!\e[0m\n"
exit 0
