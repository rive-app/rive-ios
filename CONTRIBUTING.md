# Contributing

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project.

## Getting started

To get started with building this runtime, you must install a few prerequisites:
- [Xcode](https://developer.apple.com/xcode/)
- [premake5](https://premake.github.io/)
  - For premake5, you may download the binary, making sure it's available in your `$PATH`. Moving the executable to `/usr/local/bin/` will work.
  - [Homebrew](https://brew.sh) may be used to install premake5: `$ brew install premake`

Check that your Xcode active developer directory is set to one that includes the iOS and macOS toolchains.
  - You can check your currect directory by running `$ xcode-select -p` in the command line.
  - Using your Xcode installation is a working option: `$ sudo xcode-select -s /Applications/Xcode.app`

Rive is constantly making use of the latest clang features, so please ensure your Xcode and Xcode Command Line Tools are up-to-date with the latest versions.

Next, check out this repository, making sure to use ssh, and making sure to include its submodules. It is important to use ssh to checkout this repository, rather than https, as the submodules are linked via ssh.

```bash
git clone --recurse-submodules git@github.com:rive-app/rive-ios.git
```

This runtime relies on our open-source [Rive runtime](https://github.com/rive-app/rive-runtime) in order to be built. This dependency will automatically be included if you clone this repository with `--recurse-submobules`. If you have already cloned the directory without submodules, you can update the submodules by performing the following from the **root** of your cloned repository:

```bash
cd submodules
git submodule update --init --recursive
```

Once you have cloned the repository, the prerequisites are installed, and your Xcode active developer directory is properly set, you can build this runtime by running the following from the **root** of your cloned repository:

```bash
$ ./scripts/build.sh all release
```

If the script completes successfully, then all necessary frameworks are built, and you can continue on to running the Example apps.

## Example and Preview targets / schemes

The Example app has different targets and schemes, currently for both iOS and macOS. The `Example` targets make use of the local Rive dependency (built above) and the `Preview` targets make use of a hosted version of Rive, added via Swift Package Manager, to make it easy to run without needing to do all of the local development setup above. If you're making changes to the underlying runtime and need to test the Example app, be sure to set the scheme to either `Example (iOS)` or `Example (macOS)`, depending on your platform. See [Customizing the build schemes for a project](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project) for more information.

## Releasing

After releasing a new runtime version you'll need to manually update the `rive-ios` dependency for the `Preview` targets. This is to ensure that anyone evaluating Rive is using the latest hosted version. Right click the `RiveRuntime` dependency in the inspector and select `Update Package`. If there is a major version bump, it will need to be configured in the project settings, by updating the `Up to Next Major Version` dependency rule with the new major version, in the `Package Dependencies` section for the `RiveExample` project.

### Uploading caches

If you are contributing and you have access to Rives' AWS environment, make you sure install `aws-cli` and configure it with your credentials. If you run into permission issues here `aws sts get-caller-identity` can help make sure that your local developer environment is setup to talk to AWS correctly.
See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Note: on a Mac with brew, you can simply run 'brew install awscli'

Note: the 'dependencies' directory is just a cache of what the configure.sh script downloads. It can be removed if you suspect it is out of date, and then just rerun the script (./scripts/configure.sh)

### Changing the `rive-cpp` submodule

Changes within the `RiveRuntime` target should be reflected when you make builds.

If you make changes within the `rive-cpp` submodule, you will need to compile the prebuilt libraries. This can take a reasonably long time, but as long as you are working on `rive-cpp` with no uncommitted changes, it will fall back to using the cache, so you will only need to build once.

### Testing changes

In addition to tests in the project, you may want to visually test out any changes by running the `Example (iOS)` app at the top-level. Open the `RiveExample` project in Xcode. Make sure you have built the RiveRuntime scheme at least once before testing out this application. Feel free to bring in additional Rive files into the `assets/` folder. Ensure you add the Rive files to the correct targets by checking "Add to targets: RiveExample" when dragging assets into the folder, so it can be properly included in the assets bundle and referenced accordingly in the Example app(s).

### Linting and tests

- We currently do not have any automatic linting set up.
- Tests are run on pull request, and you should be able to run tests via Xcode in the `RiveRuntime` project.

## Scripts

The `scripts` folder contains a few scripts to manage dependencies and perform builds. The main script used to build this runtime is `build.sh`. For more information on usage, you can run the script with no arguments to print some additional information. However, the most common usage will be what's referenced above: `$ build.sh all`.

## FAQ

### `Rive.h` file not found

This is probably because of missing submodules. Make sure you check out this repository with [submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules). See above for more information.
