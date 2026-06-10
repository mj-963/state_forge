# StateForge DevTools

This directory contains the Flutter web source app for the
[StateForge](../README.md) [DevTools extension](https://docs.flutter.dev/tools/devtools/extensions).

The published `state_forge` package ships the built extension from:

```text
../extension/devtools/
```

Build and copy the source app into the package extension directory with:

```sh
dart run devtools_extensions build_and_copy --source=. --dest=../extension/devtools
```

Validate the parent package extension with:

```sh
dart run devtools_extensions validate --package=..
```

The extension calls these service extensions registered by
[`state_forge`](../):

- `ext.state_forge.getStores`
- `ext.state_forge.getHistory`
