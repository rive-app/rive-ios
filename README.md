![Build Status](https://github.com/rive-app/rive-ios/actions/workflows/build_frameworks.yml/badge.svg)
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

:blue_book: [General help docs](https://help.rive.app/)

🛠 [Learning Rive](https://rive.app/learn-rive/)

## Getting started

Follow along with the link below for a quick start in getting Rive iOS/macOS integrated into your multi-platform applications.

[Getting Started with Rive in iOS](https://help.rive.app/runtimes/overview/ios)

## Supported devices

Currently, this runtime library supports a minimum iOS version of **14.0+**. Devices supported include iPhone, iPad, and Mac catalyst. macOS support supports a targeted version of **13.1**.

## Examples

Check out the `Example-iOS/` folder for an example application using the Rive iOS/macOS runtime.

Open the project in XCode and ensure the selected scheme/target is set to `Preview`/`Preview (macOS)`. These schemes make use of the hosted Rive package dependency. The other targets are for local development and require additional configuration and set-up. See [Customizing the build schemes for a project](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project) for instructions to switch schemes, and `CONTRIBUTING.md` for more information.

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

[Migration guides](https://help.rive.app/runtimes/overview/ios/migrating-from-2.x.x-to-3.x.x)

## Contributing

We love contributions! Check out our [contributing docs](./CONTRIBUTING.md) to get more details into how to run this project, the examples, and more all locally.

## Issues

Have an issue with using the runtime, or want to suggest a feature/API to help make your development life better? Log an issue in our [issues](https://github.com/rive-app/rive-ios/issues) tab! You can also browse older issues and discussion threads there to see solutions that may have worked for common problems.
