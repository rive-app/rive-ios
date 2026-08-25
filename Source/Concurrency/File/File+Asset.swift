import Foundation

extension File {
    /// Metadata describing an asset exported in a Rive file.
    public struct Asset: Sendable, Equatable {
        /// Metadata identifying an asset hosted on a CDN.
        public struct CDN: Sendable, Equatable {
            /// The base URL containing the hosted asset.
            public let baseURL: String

            /// The hosted asset's UUID.
            public let uuid: String
        }

        /// The concrete kind of file asset.
        public enum AssetType: Sendable, Equatable {
            /// An image asset.
            case image

            /// A font asset.
            case font

            /// An audio asset.
            case audio

            /// An asset kind that is not recognized by this runtime version.
            case unknown(UInt16)
        }

        /// The authored asset name stored in the Rive file.
        public let name: String

        /// The exact name used to register a replacement asset with the file's worker.
        public let uniqueName: String

        /// The asset identifier stored in the Rive file.
        public let assetID: UInt32

        /// CDN metadata for a hosted asset, or `nil` when the asset is not CDN-hosted.
        public let cdn: CDN?

        /// The asset's file extension without a leading period.
        public let fileExtension: String

        /// The concrete kind of asset.
        public let type: AssetType

        init(from dictionary: [String: Any]) throws {
            guard let name = dictionary["name"] as? String else {
                throw FileError.invalidAsset("Missing key 'name'")
            }
            guard let uniqueName = dictionary["uniqueName"] as? String else {
                throw FileError.invalidAsset("Missing key 'uniqueName'")
            }
            guard let assetID = dictionary["assetID"] as? NSNumber else {
                throw FileError.invalidAsset("Missing key 'assetID'")
            }
            guard let cdnUUID = dictionary["cdnUUID"] as? String else {
                throw FileError.invalidAsset("Missing key 'cdnUUID'")
            }
            guard let cdnBaseURL = dictionary["cdnBaseURL"] as? String else {
                throw FileError.invalidAsset("Missing key 'cdnBaseURL'")
            }
            guard let fileExtension = dictionary["fileExtension"] as? String else {
                throw FileError.invalidAsset("Missing key 'fileExtension'")
            }
            guard let typeValue = dictionary["type"] as? NSNumber else {
                throw FileError.invalidAsset("Missing key 'type'")
            }
            guard let rawType = dictionary["rawType"] as? NSNumber else {
                throw FileError.invalidAsset("Missing key 'rawType'")
            }

            self.name = name
            self.uniqueName = uniqueName
            self.assetID = assetID.uint32Value
            // Core transports both CDN strings for every file asset and gives
            // each one a default base URL. `cdnUuidStr()` is nonempty only when
            // the asset carries a valid 16-byte CDN UUID.
            self.cdn = cdnUUID.isEmpty ? nil : CDN(baseURL: cdnBaseURL, uuid: cdnUUID)
            self.fileExtension = fileExtension

            switch RiveFileAssetType(rawValue: typeValue.uint16Value) {
            case .image:
                self.type = .image
            case .font:
                self.type = .font
            case .audio:
                self.type = .audio
            default:
                self.type = .unknown(rawType.uint16Value)
            }
        }
    }
}
