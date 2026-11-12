Pod::Spec.new do |spec|
  spec.name         = "RiveRuntime"
  spec.version      = "6.30.0"
  spec.summary      = "Rive runtime for iOS, macOS, tvOS, and visionOS"
  spec.description  = "Rive is an agent-native 2D and 3D engine for games, apps, and interactive UI. Build with your coding agent through the Rive CLI, or by hand in the Rive Editor, on the same files. Open-source runtimes, no royalties or runtime fees. Rive files play natively on every major platform."
  spec.homepage     = "https://github.com/rive-app/rive-ios"
  spec.license      = { :type => "MIT", :text => <<-LICENSE
    Copyright (c) 2020-2025 Rive

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    LICENSE
  }
  spec.authors = { "Luigi Rosso" => "luigi@rive.app" }
  spec.ios.deployment_target  = '14.0'
  spec.osx.deployment_target  = '13.1'
  spec.tvos.deployment_target = '16.0'
  spec.visionos.deployment_target = '1.0'
  spec.swift_version          = '5.9'
  spec.source       = { 
    :http => "https://github.com/rive-app/rive-ios/releases/download/6.30.0/RiveRuntime.xcframework.zip",
  }
  spec.ios.vendored_frameworks = 'RiveRuntime.xcframework'
  spec.osx.vendored_frameworks = 'RiveRuntime.xcframework'
  spec.tvos.vendored_frameworks = 'RiveRuntime.xcframework'
  spec.visionos.vendored_frameworks = 'RiveRuntime.xcframework'
  spec.resource_bundles = {'runtime_ios_privacy' => ['RiveRuntime.xcframework/ios-arm64/RiveRuntime.framework/PrivacyInfo.xcprivacy']}
end
