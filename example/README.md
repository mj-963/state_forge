# StateForge Example

Movie watchlist demo for [StateForge](../README.md).

The app shows how to structure a small Flutter feature set with explicit stores:

- discovery and search flows backed by an API client
- details screens with one-time effects
- auth, watchlist, and profile stores scoped through the widget tree
- persistence through the configured StateForge storage adapter
- history controls for undo and redo

## Run

```sh
flutter pub get
flutter run
```

The discovery and search screens call the public
[TVMaze API](https://www.tvmaze.com/api), so those flows need network access.
If the device is offline, the stores surface the request failure through their
error state instead of crashing the UI.
