# Contributing

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project.

## Development workflow

To get started with the project, please install a few pre-requisites: `git-lfs` , `ninja` & [premake5](https://premake.github.io/)). Brew will install both git-lfs and ninja, for premake5 you will need to download the binary, and make sure its available on your path. Moving the executable to `/usr/local/bin/` will work.

Check out the repository, making sure to include the submodules. It is important to use ssh to checkout this repo, as the submodules are linked via ssh.

 `git clone --recurse-submodules git@github.com:rive-app/rive-ios.git`

The package relies on skia, as well as rive-cpp in order to be built. To shorten the build cycle, we rely on compiled libraries for skia, rive & rive-skia-renderer.
Run `./scripts/get_dependencies.sh` from the root folder to get everything that is needed to be set up. typically this will just pull down pre compiled libraries, but it may need to build the libraries if it cannot find them in the cache

### Uploading caches

If you are contributing and you have access to Rives' aws environment, make you sure install `aws-cli` and configure it with your credentials. Set the `RIVE_UPLOAD_IOS_ARCHIVE` env variable to `TRUE` then you should be able to run `./scripts/get_dependencies.sh`, or `RIVE_UPLOAD_IOS_ARCHIVE=TRUE ./scripts/get_dependencies.sh` and you will upload caches when feasible. 

## Changing rive-cpp/skia

Changes within the rive-ios should just be reflected when you make builds.
If you make changes within the `rive-cpp` submodule you will need to compile the prebuilt libraries, this can take a reasonably long time, but as long as you are working on rive-cpp with no uncommitted changes, it will fall back to using the cache, so you will only need to build once.

## Linting and tests

* We currently do not have any automatic linting set up.
* Tests are run on pull request, and you should be able to run tests via xcode in the `RiveRuntime` project

## Scripts

The `scripts` folder contains a few scripts to manage dependecies and perform builds.

## FAQ

### Cannot find `Rive.h`

This is probably because of missing submodules.
