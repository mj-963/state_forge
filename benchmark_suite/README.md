# StateForge Benchmark Suite

This is a local benchmark and stress-test app for
[StateForge](../README.md).

It is used to exercise:

- selective rebuild behavior across large lists
- dependency propagation through store chains
- disposal behavior during rapid async work
- rough latency measurements for repeated updates

The suite compares StateForge scenarios with comparable
[BLoC](https://pub.dev/packages/flutter_bloc) and
[Riverpod](https://pub.dev/packages/flutter_riverpod) patterns where those
scenarios are implemented. Treat the results as local engineering signals, not
universal performance claims.

## Running

From this directory:

```sh
flutter pub get
flutter test
flutter run
```

The app depends on the repository-local [`state_forge`](../) package via a path
dependency, so run it from a checkout of the full repository.
