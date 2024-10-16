//
//  RiveLogger+File.swift
//  RiveRuntime
//
//  Created by David Skuza on 9/26/24.
//  Copyright © 2024 Rive. All rights reserved.
//

import Foundation
import OSLog

enum RiveLoggerFileEvent {
    case fatalError(String)
    case error(String)
    case loadingAsset(RiveFileAsset)
    case loadedFontAssetFromURL(URL, RiveFontAsset)
    case loadedImageAssetFromURL(URL, RiveImageAsset)
    case loadedAsset(RiveFileAsset)
    case loadedFromURL(URL)
    case loadingFromResource(String)
}

extension RiveLogger {
    private static let file = Logger(subsystem: subsystem, category: "rive-file")

    @objc(logFile:error:) static func log(file: RiveFile?, error message: String) {
        log(file: file, event: .error(message))
    }

    @objc(logLoadingAsset:) static func log(loadingAsset asset: RiveFileAsset) {
        log(file: nil, event: .loadingAsset(asset))
    }

    @objc(logFontAssetLoad:fromURL:) static func log(fontAssetLoad fontAsset: RiveFontAsset, from url: URL) {
        log(file: nil, event: .loadedFontAssetFromURL(url, fontAsset))
    }

    @objc(logImageAssetLoad:fromURL:) static func log(imageAssetLoad imageAsset: RiveImageAsset, from url: URL) {
        log(file: nil, event: .loadedImageAssetFromURL(url, imageAsset))
    }

    @objc(logAssetLoaded:) static func log(assetLoaded asset: RiveFileAsset) {
        log(file: nil, event: .loadedAsset(asset))
    }

    @objc(logLoadedFromURL:) static func log(loadedFromURL url: URL) {
        log(file: nil, event: .loadedFromURL(url))
    }

    @objc(logLoadingFromResource:) static func log(loadingFromResource name: String) {
        log(file: nil, event: .loadingFromResource(name))
    }

    static func log(file: RiveFile?, event: RiveLoggerFileEvent) {
        switch event {
        case .fatalError(let message):
            _log(event: event, level: .fault) {
                Self.file.fault("\(message)")
            }
        case .error(let message):
            _log(event: event, level: .error) {
                Self.file.error("\(message)")
            }
        case .loadingAsset(let asset):
            _log(event: event, level: .debug) {
                Self.file.debug("Loading asset \(asset.name())")
            }
        case .loadedAsset(let asset):
            _log(event: event, level: .debug) {
                Self.file.debug("Loaded asset \(asset.name())")
            }
        case .loadedFontAssetFromURL(let url, let asset):
            _log(event: event, level: .debug) {
                Self.file.debug("Loaded font asset \(asset.name()) from URL: \(url)")
            }
        case .loadedImageAssetFromURL(let url, let asset):
            _log(event: event, level: .debug) {
                Self.file.debug("Loaded image asset \(asset.name()) from URL: \(url)")
            }
        case .loadedFromURL(let url):
            _log(event: event, level: .debug) {
                Self.file.debug("Loaded file \(url)")
            }
        case .loadingFromResource(let name):
            _log(event: event, level: .debug) {
                Self.file.debug("Loading resource \(name)")
            }
        }
    }

    private static func _log(event: RiveLoggerFileEvent, level: RiveLogLevel, log: () -> Void) {
        guard isEnabled,
              categories.contains(.file),
              levels.contains(level)
        else { return }

        log()
    }
}
