# rive-ios
iOS runtime for Rive

## Running the Example
To run the example, open the project in [Example-iOS directory](https://github.com/rive-app/rive-ios/tree/master/Example-iOS). The playing animation can be changed by editing ```RiveViewController(resource: "xxx", withExtension: "riv")``` in ```ContentView.swift```.

## Runtime Granularity
This is a low-level runtime, designed to give you complete control over Rive animations and how they're drawn. As such, it requires you to do some heavy-lifting and control the animation loop and timing.

We took this decision as we felt that it was important to give you as total control of your animations, and to provide a solid basis for higher-level runtimes that can implement pre-baked controllers and views for embedding Rive animations.

The runtime has two dependencies: CoreGraphics and QuartzCore. We intentionally omitted binding to UIKit or AppKit to keep the runtime generic, the intent being for higher-level runtimes to provide support for iOS and MacOS.

## Runtime Implementation
The runtime is implemented in Objective-C. Why not Swift? Rive's runtimes for the web, Android, and iOS all share a common C++ core, which implements Rive's file loading, animation control, and rendering. Objective-C++ interoperates well with C++, hence our choice. Our example code is implemented in Swift.

## Playing a Looping Animation

Let's go through a simple example of how to embed a looping animation inside your app. We're going to create a custom UIViewController and UIView that you can drop into your UI.

First thing we need to do in our controller is load a Rive file. For this, we can use the ```RiveFile``` class, which takes a byte list and length. The bytes can be loaded in whatever manner you choose: from a file or over a network; here we're loading it from the bundle.

```swift
func startRive() {
    guard let name = resourceName, let ext = resourceExt else {
        fatalError("No resource or extension name specified")
    }
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        fatalError("Failed to locate \(name) in bundle.")
    }
    guard var data = try? Data(contentsOf: url) else {
        fatalError("Failed to load \(url) from bundle.")
    }
    
    // Import the data into a RiveFile
    let bytes = [UInt8](data)
    
    data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer) in
        guard let rawPointer = riveBytes.baseAddress else {
            fatalError("File pointer is messed up")
        }
        let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
        
        guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
            fatalError("Failed to import \(url).")
        }
        
        // More to come ...
    }
}
```

Most of this code loads the raw byte data; the ```RiveFile(bytes:pointer, byteLength: UInt64(bytes.count))``` constructor initializes the animation data.

Next, we'll need to get a reference to the artboard that contains the animation we want to play. Once we have that, we access one of the animations in the artboard and create an instance from it. Then we start the animation loop.

```swift
let artboard = riveFile.artboard()

if (artboard.animationCount() == 0) {
    fatalError("No animations in the file.")
}
            
// Fetch an animation
let animation = artboard.animation(at: 0)

// Advance the artboard, this will ensure the first
// frame is displayed when the artboard is drawn
artboard.advance(by: 0)

// Start the animation loop
runTimer()
```

As this is a low-level runtime, you have to create and manage your own animation loop. Fortunately, Apple's made this easy with ```CADisplayLink```. Here's the code to run the loop and play the animation instance.

```swift
// Starts the animation timer
func runTimer() {
    displayLink = CADisplayLink(target: self, selector: #selector(tick));
    displayLink?.add(to: .main, forMode: .default)
}

// Stops the animation timer
func stopTimer() {
    displayLink?.remove(from: .main, forMode: .default)
}

// Animates a frame
@objc func tick() {
    guard let displayLink = displayLink, let artboard = artboard else {
        // Something's gone wrong, clean up and bug out
        stopTimer()
        return
    }
    
    let timestamp = displayLink.timestamp
    // last time needs to be set on the first tick
    if (lastTime == 0) {
        lastTime = timestamp
    }
    // Calculate the time elapsed between ticks
    let elapsedTime = timestamp - lastTime;
    lastTime = timestamp;
    
    // Advance the animation instance and the artboard
    instance!.advance(by: elapsedTime) // advance the animation
    instance!.apply(to: artboard)      // apply to the artboard
            
    artboard.advance(by: elapsedTime) // advance the artboard
    
    // Trigger a redraw
    self.view.setNeedsDisplay()
}
```

```tick``` is where the Rive magic happens. We first calculate how much time has elapsed since the last call to tick, storing it in ```elapsedTime```. We then advance our animation by the elapsed time, and apply the animation to the artboard. We then advance the artboard by the elapsed time. Finally, we tell our view to redraw.

Why advance the both animation instance and artboard, and not do it in one step? Rive lets you mix animations together, so you can easily apply multiple animations to the same artboard to create sophisticated animation behavior. You could also apply these animations at different elapsed times, giving you complete control over the speed of how these animations mix.

Here's the complete code for our controller:

```swift
import UIKit
import RiveRuntime

class MyRiveViewController: UIViewController {

    var resourceName: String?
    var resourceExt: String?
    var artboard: RiveArtboard?
    var instance: RiveLinearAnimationInstance?
    var displayLink: CADisplayLink?
    var lastTime: CFTimeInterval = 0
    
    init(withResource name: String, withExtension: String) {
        resourceName = name
        resourceExt = withExtension
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startRive()
    }
    
    override func loadView() {
        // Wire up an instance of MyRiveView to the controller
        let view = MyRiveView()
        view.backgroundColor = UIColor.blue
        self.view = view
    }
    
    func startRive() {
        guard let name = resourceName, let ext = resourceExt else {
            fatalError("No resource or extension name specified")
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            fatalError("Failed to locate \(name) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer) in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            
            let artboard = riveFile.artboard()
            
            self.artboard = artboard
            // update the artboard in the view
            (self.view as! MyRiveView).updateArtboard(artboard)
            
            if (artboard.animationCount() == 0) {
                fatalError("No animations in the file.")
            }
                        
            // Fetch an animation
            let animation = artboard.animation(at: 0)
            self.instance = animation.instance()
            
            // Advance the artboard, this will ensure the first
            // frame is displayed when the artboard is drawn
            artboard.advance(by: 0)
            
            // Start the animation loop
            runTimer()
        }
    }
    
    // Starts the animation timer
    func runTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick));
        displayLink?.add(to: .main, forMode: .default)
    }
    
    // Stops the animation timer
    func stopTimer() {
        displayLink?.remove(from: .main, forMode: .default)
    }
    
    // Animates a frame
    @objc func tick() {
        guard let displayLink = displayLink, let artboard = artboard else {
            // Something's gone wrong, clean up and bug out
            stopTimer()
            return
        }
        
        let timestamp = displayLink.timestamp
        // last time needs to be set on the first tick
        if (lastTime == 0) {
            lastTime = timestamp
        }
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime;
        lastTime = timestamp;
        
        // Advance the animation instance and the artboard
        instance!.advance(by: elapsedTime) // advance the animation
        instance!.apply(to: artboard)      // apply to the artboard
                
        artboard.advance(by: elapsedTime) // advance the artboard
        
        // Trigger a redraw
        self.view.setNeedsDisplay()
    }
}
```

We still need to draw our rendered animation through the view. The code's pretty short; here's the view in its entirety:

```swift
import UIKit
import RiveRuntime

class MyRiveView: UIView {

    var artboard: RiveArtboard?;
    
    func updateArtboard(_ artboard: RiveArtboard) {
        self.artboard = artboard;
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: Alignment.Center, with: Fit.Contain)
        artboard.draw(renderer)
    }
}
```

Over view is overriding its ```draw``` function and on every frame is creating a RiveRenderer, which renders an artboard to the UI. Our controller sets the artboard during initializtion and drives the view to update on every ```tick``` with ```self.view.setNeedsDisplay()```.

You can place this view in an app, and the runtime will continuously play the looping animation. If it's a one-shot animation, it'll play it once and then stop.

The code for this example is in the [Example-iOS directory](https://github.com/rive-app/rive-ios/tree/master/Example-iOS).