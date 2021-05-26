# rive-ios

iOS runtime for [Rive](https://rive.app/)

## Create and ship interactive animations to any platform

[Rive](https://rive.app/) is a real-time interactive design and animation tool. Use our collaborative editor to create motion graphics that respond to different states and user inputs. Then load your animations into apps, games, and websites with our lightweight open-source runtimes.

## Beta Release

This is the Android runtime for [Rive](https://rive.app), currently in beta. The api is subject to change as we continue to improve it. Please file issues and PRs for anything busted, missing, or just wrong.


# Installing rive-ios

## Via github

You can clone this repository and include the RiveRuntime.xcodeproj to build a dynamic or static library.

When pulling down this repo, you'll need to make sure to also pull down the submodule which contains the C++ runtime that our iOS runtime is built upon. The easiest way to do this is to run this:

```
git clone --recurse-submodules git@github.com:rive-app/rive-ios
```

When updating, remember to also update the submodule with the same command.

```
git submodule update --init
```

## Via Pods

We are in the process of getting a pod available in [cocoapods](https://cocoapods.org/).

While we are working out any kinks, we are publishing our pod to a temporary github repo, which you can install by including placeholder while we finalize any kinks.

```
pod 'RiveRuntime', :git => 'git@github.com:rive-app/test-ios.git'
```

Once you have installed the pod, you can run `import RiveRuntime` to have access to our higher level views or build on top of our bindings to control your own animation loop.

# Examples

There is an example project next to the runtimes. 

The examples show simple ways of adding animated views into your app, how to add buttons & slider controls, how to use state machines & how to navigate the contents of a rive file programatically. 

To run the example, open the `Rive.xcworkspace` in Xcode and run the `RiveExample` project.  