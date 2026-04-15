//
//  RiveUIFileListener.hpp
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveUIFileListener_hpp
#define RiveUIFileListener_hpp

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveFileListener
 *
 * Protocol defining the interface for objects that receive asynchronous
 * notifications about file-related operations from the command queue.
 *
 * This protocol follows the observer pattern: you provide an observer object
 * implementing this protocol when making file operations (e.g., loadFile:).
 * The command queue will call the appropriate methods on your observer when
 * operations complete, fail, or return data.
 *
 * Request ID correlation:
 * Each command queue operation accepts a requestID parameter. When the
 * operation completes, the corresponding listener method is called with the
 * same requestID. Use this to correlate requests with responses, especially
 * when making multiple concurrent requests.
 *
 * Threading:
 * Listener methods are typically called on the main thread, but this is
 * implementation-dependent. Ensure your implementations are thread-safe.
 *
 * Observers implementing this protocol will be notified when:
 * - Files are successfully loaded or deleted
 * - File operations encounter errors
 * - Artboard names, view model names, and other file metadata are retrieved
 */
NS_SWIFT_NAME(FileListener)
@protocol RiveFileListener <NSObject>

/**
 * Called when a Rive file is successfully loaded by the command server.
 *
 * @param handle The unique identifier of the loaded file. This handle
 *               can be used for subsequent file operations.
 * @param requestID The identifier of the loading request. This can be used
 *                  to correlate the loading with a specific operation or
 *                  to track the loading request through the system.
 */
- (void)onFileLoaded:(uint64_t)handle requestID:(uint64_t)requestID;

/**
 * Called when a Rive file is deleted from the command server.
 *
 * @param handle The unique identifier of the deleted file. This handle
 *               corresponds to the file that was previously loaded or
 * referenced.
 * @param requestID The identifier of the deletion request. This can be used
 *                  to correlate the deletion with a specific operation or
 *                  to track the deletion request through the system.
 */
- (void)onFileDeleted:(uint64_t)handle requestID:(uint64_t)requestID;

/**
 * Called when a file loading operation encounters an error.
 *
 * @param fileHandle The file handle that was being loaded when the error
 * occurred
 * @param requestID The identifier of the failed loading request
 * @param message A human-readable error message describing what went wrong
 */
- (void)onFileError:(uint64_t)fileHandle
          requestID:(uint64_t)requestID
            message:(NSString*)message;

/**
 * Called when artboard names are listed for a file.
 *
 * @param fileHandle The unique identifier of the file
 * @param requestID The identifier of the listing request
 * @param names Array of artboard names in the file
 */
- (void)onArtboardsListed:(uint64_t)fileHandle
                requestID:(uint64_t)requestID
                    names:(NSArray<NSString*>*)names;

/**
 * Called when view model names are listed for a file.
 *
 * @param fileHandle The unique identifier of the file
 * @param requestID The identifier of the listing request
 * @param names Array of view model names in the file
 */
- (void)onViewModelsListed:(uint64_t)fileHandle
                 requestID:(uint64_t)requestID
                     names:(NSArray<NSString*>*)names;

/**
 * Called when view model instance names are listed for a file.
 *
 * @param fileHandle The unique identifier of the file
 * @param requestID The identifier of the listing request
 * @param viewModelName The name of the view model
 * @param names Array of view model instance names
 */
- (void)onViewModelInstanceNamesListed:(uint64_t)fileHandle
                             requestID:(uint64_t)requestID
                         viewModelName:(NSString*)viewModelName
                                 names:(NSArray<NSString*>*)names;

/**
 * Called when view model properties are listed for a file.
 *
 * @param fileHandle The unique identifier of the file
 * @param requestID The identifier of the listing request
 * @param viewModelName The name of the view model
 * @param properties Array of property dictionaries, each containing:
 *                   - "type": NSNumber with RiveViewModelInstanceDataType value
 *                   - "name": NSString with the property name
 *                   - "metaData": NSString with optional metadata (may be
 * empty)
 */
- (void)onViewModelPropertiesListed:(uint64_t)fileHandle
                          requestID:(uint64_t)requestID
                      viewModelName:(NSString*)viewModelName
                         properties:
                             (NSArray<NSDictionary<NSString*, id>*>*)properties;

/**
 * Called when view model enums are listed for a file.
 *
 * @param fileHandle The unique identifier of the file
 * @param requestID The identifier of the listing request
 * @param enums Array of enum dictionaries, each containing:
 *              - "name": NSString with the enum name
 *              - "values": NSArray<NSString*> with the enum values
 */
- (void)onViewModelEnumsListed:(uint64_t)fileHandle
                     requestID:(uint64_t)requestID
                         enums:(NSArray<NSDictionary<NSString*, id>*>*)enums;

@end

NS_ASSUME_NONNULL_END

#endif
