//
//  RiveUIArtboardListener.h
//  RiveRuntime
//
//  Created by David Skuza on 8/18/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveArtboardListener_h
#define RiveArtboardListener_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveArtboardListener
 *
 * Protocol defining the interface for objects that receive asynchronous
 * notifications about artboard-related operations from the command queue.
 *
 * This protocol follows the observer pattern: you provide an observer object
 * implementing this protocol when creating artboards (e.g.,
 * createArtboardNamed:). The command queue will call the appropriate methods on
 * your observer when artboard operations complete or fail.
 *
 * Request ID correlation:
 * Each command queue operation accepts a requestID parameter. When the
 * operation completes, the corresponding listener method is called with the
 * same requestID. Use this to correlate requests with responses.
 *
 * Threading:
 * Listener methods are typically called on the main thread, but this is
 * implementation-dependent. Ensure your implementations are thread-safe.
 *
 * Observers implementing this protocol will be notified when:
 * - State machine names are retrieved from an artboard
 * - Default view model information is retrieved
 * - Artboard operations encounter errors
 */
NS_SWIFT_NAME(ArtboardListener)
@protocol RiveArtboardListener <NSObject>

/**
 * Called when state machine names are listed for a specific artboard.
 *
 * This method is invoked by the command queue when a request for state machine
 * names completes. The observer can use this information to update its state
 * or notify other components about available state machines.
 *
 * @param artboardHandle The handle of the artboard that was queried.
 * @param names An array of state machine names available on the artboard.
 * @param requestID The unique identifier for the request that completed.
 */
- (void)onStateMachineNamesListed:(uint64_t)artboardHandle
                            names:(NSArray<NSString*>*)names
                        requestID:(uint64_t)requestID;

/**
 * Called when an artboard encounters an error during operations.
 *
 * This method is invoked by the command queue when an artboard operation
 * fails. The observer can use this information to handle errors gracefully
 * and notify users about issues.
 *
 * @param artboardHandle The handle of the artboard that encountered the error.
 * @param requestID The unique identifier for the request that failed.
 * @param message A human-readable error message describing what went wrong.
 */
- (void)onArtboardError:(uint64_t)artboardHandle
              requestID:(uint64_t)requestID
                message:(NSString*)message;

/**
 * Called when an artboard delete request completes.
 *
 * @param artboardHandle The handle of the artboard that was deleted.
 * @param requestID The unique identifier for the request that completed.
 */
- (void)onArtboardDeleted:(uint64_t)artboardHandle
                requestID:(uint64_t)requestID;

/**
 * Called when default view model information is received for an artboard.
 *
 * This method is invoked by the command queue when a request for default view
 * model information completes. The observer can use this information to
 * understand which view model and instance name are associated with the
 * artboard by default.
 *
 * @param artboardHandle The handle of the artboard that was queried.
 * @param requestID The unique identifier for the request that completed.
 * @param viewModelName The name of the default view model for this artboard.
 * @param instanceName The name of the default view model instance for this
 * artboard.
 */
- (void)onDefaultViewModelInfoReceived:(uint64_t)artboardHandle
                             requestID:(uint64_t)requestID
                         viewModelName:(NSString*)viewModelName
                          instanceName:(NSString*)instanceName;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveArtboardListener_h */
