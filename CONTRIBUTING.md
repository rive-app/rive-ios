# Contributing

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project.

## Development workflow

To get started with the project, please install a few pre-requisites:  [ninja](https://formulae.brew.sh/formula/ninja) & [premake5](https://premake.github.io/). [Homebrew](https://formulae.brew.sh/) will install both [git-lfs](https://formulae.brew.sh/formula/git-lfs) and ninja, for premake5 you will need to download the binary, and make sure its available on your path. Moving the executable to `/usr/local/bin/` will work.

Check out this repository, making sure to include the submodules. It is important to use ssh to checkout this repo, as the submodules are linked via ssh.

 `git clone --recurse-submodules git@github.com:rive-app/rive-ios.git`

The package relies on [Skia](https://skia.org/), as well as [rive-cpp](https://github.com/rive-app/rive-cpp) in order to be built. To shorten the build cycle, we rely on compiled libraries for skia, rive & rive-skia-renderer.
The `./scripts/build.sh all` script will download or build appropriate libraries, be sure to run configure when making changes to our rive-cpp submodule.

### Uploading caches

If you are contributing and you have access to Rives' AWS environment, make you sure install `aws-cli` and configure it with your credentials. If you run into permission issues here `aws sts get-caller-identity` can help make sure that your local developer environment is setup to talk to AWS correctly.
See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Note: on a Mac with brew, you can simply run 'brew install awscli'

Note: the 'dependencies' directory is just a cache of what the configure.sh script downloads. It can be removed if you suspect it is out of date, and then just rerun the script (./scripts/configure.sh)

### Changing rive-cpp/skia

Changes within the rive-ios should just be reflected when you make builds.
If you make changes within the `rive-cpp` submodule you will need to compile the prebuilt libraries, this can take a reasonably long time, but as long as you are working on rive-cpp with no uncommitted changes, it will fall back to using the cache, so you will only need to build once.

### Testing changes
In addition to tests in the project, you may want to visually test out any changes by running the `Example-iOS` app at the top-level. Open the `RiveExample.xcodeproj` project in XCode. Make sure you have the local build of iOS run before testing out this application. Feel free to bring in additional Rives to the `assets/` folder. Ensure you add the Rive to the targets by checking the checkbox "Add to targets: RiveExample" when dragging assets into the folder so it can be properly included in the assets bundle and referenced accordingly in the example app.

### Linting and tests

* We currently do not have any automatic linting set up.
* Tests are run on pull request, and you should be able to run tests via xcode in the `RiveRuntime` project

## Scripts

The `scripts` folder contains a few scripts to manage dependencies and perform builds.

## FAQ

### `Rive.h` file not found

This is probably because of missing submodules. Make sure you check out rive with [submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

### `rive/renderer.hpp` file not found

This is likely because the `script/configure.py` has not been run yet.
