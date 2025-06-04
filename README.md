[![Emerge badge](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.emergetools.com%2Fapi%2Fv2%2Fpublic_new_build%3FexampleId%3Drive.app.ios.runtime.RiveRuntime%26platform%3Dios%26badgeOption%3Dversion_and_max_install_size%26buildType%3Drelease&query=%24.badgeMetadata&logo=apple&label=RiveRuntime)](https://www.emergetools.com/app/example/ios/rive.app.ios.runtime.RiveRuntime/release)
![Discord badge](https://img.shields.io/discord/532365473602600965)
![Twitter handle](https://img.shields.io/twitter/follow/rive_app.svg?style=social&label=Follow)


# Rive iOS

![Rive hero image](https://cdn.rive.app/rive_logo_dark_bg.png)

An iOS/macOS runtime library for [Rive](https://rive.app) that supports both UIKit, AppKit, and SwiftUI.

The library is distributed both through Swift Package Manager and Cocoapods.

## Table of contents

- :star: [Rive Overview](#rive-overview)
- 🚀 [Getting Started & API docs](#getting-started)
- :mag: [Supported Devices](#supported-devices)
- :books: [Examples](#examples)
- :runner: [Migration Guides](#migration-guides)
- 👨‍💻 [Contributing](#contributing)
- :question: [Issues](#issues)

## Rive overview

[Rive](https://rive.app) is a real-time interactive design and animation tool that helps teams create and run interactive animations anywhere. Designers and developers use our collaborative editor to create motion graphics that respond to different states and user inputs. Our lightweight open-source runtime libraries allow them to load their animations into apps, games, and websites.

:house_with_garden: [Homepage](https://rive.app/)

:blue_book: [Rive docs](https://rive.app/docs/)

🛠 [Rive Community](https://community.rive.app/)

## Getting started

To get started with Rive Apple runtime, check out the following resources:

- [Getting Started with the Rive Apple runtime](https://rive.app/docs/runtimes/apple/apple)

For more information, see the Runtime sections of the Rive help documentation:

- [Animation Playback](https://rive.app/docs/runtimes/animation-playback)
- [Layout](https://rive.app/docs/runtimes/layout)
- [State Machines](https://rive.app/docs/runtimes/state-machines)
- [Rive Text](https://rive.app/docs/runtimes/text)
- [Rive Events](https://rive.app/docs/runtimes/rive-events)
- [Loading Assets](https://rive.app/docs/runtimes/loading-assets)
- [Data Binding](https://rive.app/docs/runtimes/data-binding)

## Supported platforms

Supported platforms include iOS, macOS, tvOS, and visionOS. For the minimum supported versions, see [Package.swift](./Package.swift).

## Examples

Check out the `Example-iOS/` folder for code examples on how to use the Rive Apple runtime.

Open `RiveRuntime.xcworkspace` in Xcode and ensure the selected scheme is set to `Preview (iOS)` or `Preview (macOS)`, based on what platform you want to preview. These schemes make use of the Swift Package Manager package of the Rive Apple runtime, and are the schemes you should use to preview the Rive examples.

**Note**: The other targets are for local development and require additional configuration and set-up. See [Customizing the build schemes for a project](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project) for instructions to switch schemes, and [CONTRIBUTING.md](./CONTRIBUTING.md) for more information. You should not use these schemes unless you are making changes to the underlying C++ runtime.

The example showcases a number of ways to use the high-level `RiveViewModel` API through UIKit and SwiftUI examples, including:

- Setting a Rive file via a URL or asset in the bundle
- Setting layout and loop mode options
- Displaying single or multiple animations / artboards on one component
- Setting up and maniuplating a state machine via inputs
- ...and more!

### Awesome Rive

For even more examples and resources on using Rive at runtime or in other tools, checkout the [awesome-rive](https://github.com/rive-app/awesome-rive) repo.

## Migration guides

Using an older version of the runtime and need to learn how to upgrade to the latest version? Check out the migration guides below in our help center that help guide you through version bumps; breaking changes and all!

[Migration Guides](https://rive.app/docs/runtimes/apple/migrating-from-5.x.x-to-6.x.x)

## Contributing

We love contributions! Check out our [contributing docs](./CONTRIBUTING.md) to get more details into how to run this project, the examples, and more all locally.

## Issues

Have an issue with using the runtime, or want to suggest a feature/API to help make your development life better? Log an issue in our [issues](https://github.com/rive-app/rive-ios/issues) tab! You can also browse older issues and discussion threads there to see solutions that may have worked for common problems.
