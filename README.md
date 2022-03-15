![Build Status](https://github.com/rive-app/rive-ios/actions/workflows/build_frameworks.yml/badge.svg) 
![Discord badge](https://img.shields.io/discord/532365473602600965)
![Twitter handle](https://img.shields.io/twitter/follow/rive_app.svg?style=social&label=Follow)
# rive-ios

iOS runtime for [Rive](https://rive.app/)

Further runtime documentation can be found in [Rive's help center](https://help.rive.app/runtimes).

## Create and ship interactive animations to any platform

[Rive](https://rive.app/) is a real-time interactive design and animation tool. Use our collaborative editor to create motion graphics that respond to different states and user inputs. Then load your animations into apps, games, and websites with our lightweight open-source runtimes.

## Beta Release

This is the iOS runtime for [Rive](https://rive.app), currently in beta. The api is subject to change as we continue to improve it. Please file issues and PRs for anything busted, missing, or just wrong.

# Installing rive-ios


## Via Cocoapods

To install our pod, simply add the following to [cocoapods](https://cocoapods.org/) and run `pod install`.

```ruby
pod 'RiveRuntime'
```

Once you have installed the pod, you can run

```swift
import RiveRuntime
```

to have access to our higher level views or build on top of our bindings to control your own animation loop.

## Via Swift Package Manager
To install via Swift Package Manager, in the package finder in xcode, search with the Github repository name: `https://github.com/rive-app/rive-ios`

# Examples

There is an example project next to the runtimes.

The examples show simple ways of adding animated views into your app, how to add buttons & slider controls, how to use state machines & how to navigate the contents of a rive file programatically.

To run the example, open the `Rive.xcworkspace` in Xcode and run the `RiveExample` project.  

# Overview

We have provided high level Swift controller and a UIkit view to easily add rive into your application. All of this is built ontop of an objective c layer that allows for fine grained granular animation control.

## UIKit

### RiveView

The simplest way of adding a riveView to a controller is probably to just set it as the controllers view when it is loaded.

```swift
class SimpleAnimationViewController: UIViewController {
    let resourceName = "truck_v7"
    
    override public func loadView() {
        super.loadView()

        guard let riveFile = RiveFile(byteArray: getResourceBytes(resourceName: resourceName)) else {
            fatalError("Failed to load RiveFile")
        }
        let view = RiveView(riveFile:riveFile)
        self.view = view
    }
}
```

The RiveView will autoplay the first animation found in the riveFile, our code for loading the local resource as UInt8 data is here.

```swift
func getResourceBytes(resourceName: String, resourceExt: String=".riv") -> [UInt8] {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) else {
        fatalError("Failed to locate \(resourceName) in bundle.")
    }
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    return [UInt8](data)
}
```

The riveView can be further customized to select which animation to play, or how to fit the animation into the view space. A lot of configuration is possible on the RiveView, playback controls are added as functions on the view, and to change which file or artboard is being displayed, use `.configure`.

### Layout

The rive view can be further customized as part of specifying layout attributes.

fit can be specified to determine how the animation should be resized to fit its container. The available choices are `.fitFill` , `.fitContain` , `.fitCover` , `.fitFitWidth` , `.fitFitHeight` , `.fitNone` , `.fitScaleDown`

alignment informs how it should be aligned within the container. The available choices are `alignmentTopLeft`, `alignmentTopCenter`, `alignmentTopRight`, `alignmentCenterLeft`, `alignmentCenter`, `alignmentCenterRight`, `alignmentBottomLeft`, `alignmentBottomCenter`, `alignmentBottomRight`.

This can be specified when instantiating the view

```swift
let view = RiveView(
    riveFile:riveFile, 
    fit: .fitFill,
    alignment: .alignmentBottomLeft
)
```

or anytime afterwards.

```swift
view.fit = .fitCover
view.alignment = .alignmentCenter
```

### Playback Controls

Animations can be controlled in many ways, by default loading a RiveView with a riveFile will autoplay the first animation on the first artboard. The artboard and animation can be specified by name here.

```swift
let riveView = RiveView(
    riveFile: riveFile,
    fit: .fitContain,
    alignment: .alignmentCenter,
    artboard: "Square",
    animation: "rollaround", 
    autoplay: true 
)
```

furthermore animations can be controlled later too:

To play an animation named rollaround.

```swift
riveView.play(animationName: "rollaround")
```

multiple animations can play at the same time, and additional animations can be added at any time

```swift
riveView.play(
    animationNames: ["bouncing", "windshield_wipers"]
)
```

When playing animations, the Loop Mode and direction of the animations can also be set per animation.

```swift
riveView.play(
    animationNames: ["bouncing", "windshield_wipers"],
    loop: .loopOneShot,
    direction: .directionBackwards
)
```

Similarly animations can be paused, or stopped, either all at the same time, or one by one.

```swift
riveView.stop()
riveView.stop(animationName:"bouncing")
riveView.stop(animationNames:["bouncing", "windshield_wipers"])
```

```swift
riveView.pause()
riveView.pause(animationName:"bouncing")
riveView.pause(animationNames:["bouncing", "windshield_wipers"])
```

### Mixing

Mixing goes further than just playing multiple animations at the same time, animations can use a mix factor between 0 and 1, to allow multiple animations effects to blend together. The high level views do not expose this currently. but you can wrap your own render loop around the core libraries. The advance function is where you can specify a mix factor.

### Delegates & Events

The rive ios runtimes allow for delegates that can be provided to the RiveView. If provided these delegates will be fired whenever a matching event is triggered.

There are the following delegates `LoopDelegate`, `PlayDelegate`, `PauseDelegate`, `StopDelegate`, `StateChangeDelegate`

You can crete your own delegate like this, implementing as many protocols are are needed.

```swift
class MyDelegate: PlayDelegate, LoopDelegate {
    func loop(_ animationName: String, type: Int) {
        // do things when the animation loops playing.
    }
    
    func play(_ animationName: String, isStateMachine: Bool) {
        // do things when the animation starts playing.
    }
}
```

To use a delegate simply pass it to the view on instantiation

```swift
let delegate = MyDelegate()

let view = RiveView(
    riveFile:riveFile, 
    loopDelegate: delegate,
    playDelegate: delegate,
)
```

or attach it later

```swift
view.loopDelegate = delegate
```
## Blend modes 

Rive allows the artist to set blend modes on shapes to determine how they are to be merged with the rest of the animation.

Each runtime is supporting the various blend modes natively, this means that there are some discrepancies in how blend modes end up being applied, we have a test file that is shipped inside the application that highlights the differences.

For ios, hue and saturation blend modes do not match the original.

Original | iOS             |  
:-------------------------:|:-------------------------:
![Source](images/editor.png ) | ![iOS](images/ios.png)  


## Developing `rive-ios`

please see [CONTRIBUTING.md](/CONTRIBUTING.md) for information on how to get setup and running with developing `rive-ios`