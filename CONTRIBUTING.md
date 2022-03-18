# Contributing

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project.

## Development workflow

To get started with the project, please install a few pre-requisites:  `ninja` & [premake5](https://premake.github.io/)). Brew will install both git-lfs and ninja, for premake5 you will need to download the binary, and make sure its available on your path. Moving the executable to `/usr/local/bin/` will work.

Check out the repository, making sure to include the submodules. It is important to use ssh to checkout this repo, as the submodules are linked via ssh.

 `git clone --recurse-submodules git@github.com:rive-app/rive-ios.git`

The package relies on skia, as well as rive-cpp in order to be built. To shorten the build cycle, we rely on compiled libraries for skia, rive & rive-skia-renderer.
The `./scripts/configure.sh` script will download or build appropriate libraries, be sure to run configure when making changes to our rive-cpp submodule. 

### Uploading caches

If you are contributing and you have access to Rives' aws environment, make you sure install `aws-cli` and configure it with your credentials. Set the `RIVE_UPLOAD_IOS_ARCHIVE` env variable to `TRUE` then you should be able to run `./scripts/configure.sh`, or `RIVE_UPLOAD_IOS_ARCHIVE=TRUE ./scripts/configure.sh` and you will upload caches when feasible. 

To force a rebuild, add `rebuild` as an argument `RIVE_UPLOAD_IOS_ARCHIVE=TRUE ./scripts/configure.sh rebuild`

If you run into permission issues here `aws sts get-caller-identity` can help make sure that your local developer environment is setup to talk to AWS correctly

## Changing rive-cpp/skia

Changes within the rive-ios should just be reflected when you make builds.
If you make changes within the `rive-cpp` submodule you will need to compile the prebuilt libraries, this can take a reasonably long time, but as long as you are working on rive-cpp with no uncommitted changes, it will fall back to using the cache, so you will only need to build once.

## Linting and tests

* We currently do not have any automatic linting set up.
* Tests are run on pull request, and you should be able to run tests via xcode in the `RiveRuntime` project

## Scripts

The `scripts` folder contains a few scripts to manage dependencies and perform builds.

## FAQ

### `Rive.h` file not found

This is probably because of missing submodules. Make sure you check out rive with [submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

### `rive/renderer.hpp` file not found

This is likely because the `script/configure.py` has not been run yet.
