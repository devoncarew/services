[![services](https://github.com/devoncarew/services/actions/workflows/build.yaml/badge.svg)](https://github.com/devoncarew/services/actions/workflows/build.yaml)

A lightweight version of a DartPad backend.

## Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart) like
this:

```
$ dart run bin/server.dart
Server listening on port 8080
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8080/api/version
{"dartVersion":"3.0.5","flutterVersion":"3.10.5"}
```

## Running with Docker

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
can build and run with the `docker` command:

```
$ docker build . -t myserver
$ docker run -it -p 8080:8080 myserver
Server listening on port 8080
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8080/api/version
{"dartVersion":"3.0.5","flutterVersion":"3.10.5"}
```

You should see the logging printed in the first terminal:
```
2023-06-23T22:50:18.861781  0:00:00.003654 GET     [200] /api/version
```
