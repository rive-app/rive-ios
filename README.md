![Build Status](https://github.com/rive-app/rive-ios/actions/workflows/build_frameworks.yml/badge.svg) 
![Discord badge](https://img.shields.io/discord/532365473602600965)
![Twitter handle](https://img.shields.io/twitter/follow/rive_app.svg?style=social&label=Follow)
# rive-ios

iOS runtime for [Rive](https://rive.app/)

Further runtime documentation can be found in [Rive's help center](https://help.rive.app/runtimes).

## Create and ship interactive animations to any platform
[Rive](https://rive.app/) is a real-time interactive design and animation tool. Use our collaborative 
editor to create motion graphics that respond to different states and user inputs. Then load your animations 
into apps, games, and websites with our lightweight open-source runtimes.

## Beta Release
This is the iOS runtime for [Rive](https://rive.app), currently in beta. The api is subject to change 
as we continue to improve it. Please file issues and PRs for anything busted, missing, or just wrong.

# Installing rive-ios
## Via Swift Package Manager
To install via Swift Package Manager, in the package finder in xcode, search with the Github repository name: `https://github.com/rive-app/rive-ios`

Once you have installed the package, you can run

```swift
import RiveRuntime
```

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

# Examples
There is an demo project in a folder called Demo-App that shows how simple it is to display beautiful animations with very few lines of code.

There is also a more in-depth example project that show many ways of adding animated views into your app, how to add buttons & slider controls, how 
to use state machines & how to navigate the contents of a rive file programatically.

To run the example, open the `Rive.xcworkspace` in Xcode and run the `RiveExample` project. Check out the 
Contributing docs to get set up. 

# Overview
We have provided high level Swift controller and a UIkit view to easily add Rive into your application. All of 
this is built ontop of an objective c layer that allows for fine grained granular animation control.

## SwiftUI

In both SwiftUI and UIKit/Storyboard usage, you import the `RiveRuntime` into your appropriate files and interface with the `RiveViewModel` to instantiate and control Rive files.

### RiveViewModel
The simplest way of adding Rive to a View is the following:

```swift
struct AnimationView: View {
    var body: some View {
        RiveViewModel(fileName: "truck").view()
    }
}
```

Don't forget to call the `.view()` method in the View body! See additional usage below for more configuration options.

## UIKit
### RiveViewModel
The simplest way of adding Rive to a controller is to make a RiveViewModel and set its view as
the `RiveView` when it is loaded.

```swift
class AnimationViewController: UIViewController {
    @IBOutlet weak var riveView: RiveView!
    
    // Load the truck_v7 resource assets
    var viewModel = RiveViewModel(fileName: "truck_v7")

    override public func viewDidLoad() {
        viewModel.setView(riveView)
    }
}
```

Rive will autoplay the first animation found in the Rive file passed in. You can also set the Rive file via a 
URL like so:

```swift
class AnimationViewController: UIViewController {
    @IBOutlet weak var riveView: RiveView!
    var viewModel = RiveViewModel(webURL: "https://cdn.rive.app/animations/vehicles.riv")

    override public func viewDidLoad() {
        viewModel.setView(riveView)
    }
}
```

The `RiveViewModel` can be further customized to select which animation to play, or how to fit the animation 
into the view space.

### Layout
The Rive view can be further customized as part of specifying layout attributes.

`fit` can be specified to determine how the animation should be resized to fit its container. The available 
choices are: 
- `.fill` 
- `.contain`
- `.cover`
- `.fitWidth`
- `.fitHeight`
- `.scaleDown`
- `.noFit`

`alignment` informs how it should be aligned within the container. The available choices are: 
- `topLeft`
- `topCenter`
- `topRight`
- `centerLeft`
- `center`
- `centerRight`
- `bottomLeft`
- `bottomCenter`
- `bottomRight`

By default, if no `fit` or `alignment` properties are set on the `RiveViewModel`, the view will be set 
with `.contain` and `.center`.

To understand more on these options, check out the help docs [here](https://help.rive.app/runtimes/layout#fit).

To add layout options, you can set it below like:

```swift
let viewModel = RiveViewModel(
    fileName: "truck_v7", 
    fit: .fill,
    alignment: .bottomLeft
)
```

or anytime afterwards.

```swift
viewModel.fit = .cover
viewModel.alignment = .center
```

### Playback Controls
Animations can be controlled in many ways. Again by default, loading a RiveViewModel will autoplay the first 
animation on the first artboard. The artboard and animation can be specified by name however if there 
are multiple artboards and/or animations defined in the Rive file.

```swift
let viewModel = RiveViewModel(
    riveFile: "artboard_animations",
    animationName: "rollaround",
    fit: .contain,
    alignment: .center,
    autoplay: true,
    artboardName: "Square"
)
```

Furthermore animations can be controlled later too:

To play an animation named "rollaround":

```swift
viewModel.play(animationName: "rollaround")
```

When playing animations, the loop mode and direction of the animations can also be set:

```swift
viewModel.play(
    animationName: "rollaround",
    loop: .oneShot,
    direction: .backwards
)
```

Similarly, animations can be paused or stopped.

```swift
viewModel.stop()
```

```swift
viewModel.pause()
```

### Delegates & Events
The `rive-ios` runtime allows for delegates that can be set on the `RiveViewModel`. If provided, 
these delegates will be fired whenever a matching event is triggered to be able to hook into and 
listen for certain events in the Rive animation cycle.

Currently, there exist the following delegates: 
- `RivePlayerDelegate` - Hook into the playback events
- `RiveStateMachineDelegate` - Hook into state changes on a state machine lifecycle

You can create your own delegate or mix in with the `RiveViewModel`, implementing as many protocols 
as are needed. Below is an example of how to customize a RiveViewModel's implementation of 
the `RivePlayerDelegate`:

```swift
class FancyViewModel: RiveViewModel {
    init() {
        super.init(fileName: "fancy_rive_file", animationName: "Drive")
    }

    override func player(loopedWithModel riveModel: RiveModel?, type: Int) {
        // do things when the animation loops.
    }
    
    override func player(playedWithModel riveModel: RiveModel?) {
        // do things when the animation starts playing.
    }

    override func player(pausedWithModel riveModel: RiveModel?) {
        // do things when the animation is paused.
    }
    
    override func player(stoppedWithModel riveModel: RiveModel?) {
        // do things when the animation is stopped.
    }
    
    override func player(didAdvanceby seconds: Double, riveModel: RiveModel?) {
        // do something every time the RiveView advances during its render loop
    }
}
```

Then you would instantiate your view model and configure it with the `RiveView` as you normally would:

```swift
class FancyAnimationViewController: UIViewController {
    @IBOutlet weak var riveView: RiveView!
    var fancyVM = FancyViewModel()
    
    override func viewDidLoad() {
        fancyVM.setView(riveView)
    }
}
```

## Blend modes 
Rive allows the artist to set blend modes on shapes to determine how they are to be merged with the
rest of the animation.

Each runtime is supporting the various blend modes natively, this means that there are some discrepancies 
in how blend modes end up being applied, we have a test file that is shipped inside the application that 
highlights the differences.

For ios, hue and saturation blend modes do not match the original.

Original | iOS             |  
:-------------------------:|:-------------------------:
![Source](images/editor.png ) | ![iOS](images/ios.png)  


## Developing `rive-ios`
please see [CONTRIBUTING.md](/CONTRIBUTING.md) for information on how to get setup and running with 
developing `rive-ios`
