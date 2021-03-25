#!/bin/sh

DIR=$(dirname "$0")

host=$@
[[ -z $host ]] && host=localhost

http_response=`wget --server-response http://$host:8080 --output-document $DIR/index.html 2>&1 | awk '/^  HTTP/{print $2}'`

if [[ -z `diff $DIR/index.html $DIR/expected_response.html` && $http_response=200 ]];then
	rm $DIR/index.html
	echo -e "\n\e[32mTest passed!\e[0m\n"
	exit 0
fi

rm $DIR/index.html
echo -e "\n\e[31mTest failed!\e[0m\n"
exit 1
