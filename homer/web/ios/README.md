# Homer for iOS

The native app is written in SwiftUI and targets iOS 17 or later.

## Run the menu

1. In Xcode, create an iOS App named `Homer` with SwiftUI as its interface.
2. Replace the generated app and content-view files with the files in `Homer/`.
3. Build and run on an iPhone simulator.

`MainMenuView` passes an explicit `HomerMode` value through `NavigationStack`.
The placeholder destinations are intentionally ready to be replaced by the Bard,
Judge, and Battle screens.
