# ngxjs
This nginx container with support modules njs and Brotli, also use BoringSSL instead OpenSSL.

## Testing

```bash
$ docker run -p 8080:80 ngxjs:v0.0.2
$ ./test/test.sh

Test passed!
```

## Examples

Contains into `./examples`
