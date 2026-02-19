//
//  RiveCommandQueue.h
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveCommandQueue_h
#define RiveCommandQueue_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <RiveRuntime/RiveEnums.h>

@protocol RiveCommandServerProtocol;
@protocol RiveFileListener;
@protocol RiveArtboardListener;
@protocol RiveViewModelInstanceListener;
@protocol RiveRenderImageListener;
@protocol RiveFontListener;
@protocol RiveAudioListener;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveCommandQueueProtocol
 *
 * Defines the Objective-C interface for the Rive command queue, which provides
 * a thread-safe mechanism for queuing and executing Rive operations.
 *
 * The command queue architecture separates command submission (on the main
 * thread) from command processing (on a background thread via
 * RiveCommandServer). This design allows the UI to remain responsive while Rive
 * files are loaded, artboards are instantiated, and animations are advanced.
 *
 * All operations are asynchronous and use request IDs to correlate requests
 * with responses delivered through listener protocols. Handles (uint64_t) are
 * used to reference files, artboards, state machines, and other resources
 * created through the queue.
 *
 * To use the command queue:
 * 1. Create a RiveCommandQueue instance
 * 2. Create a RiveCommandServer with the queue and start it on a background
 * thread via serveUntilDisconnect.
 * 3. Call start() to begin accepting commands
 * 4. Submit commands using the protocol methods
 * 5. Receive responses via listener protocol callbacks
 * 6. Call disconnect() and stop() when done
 */
NS_SWIFT_NAME(CommandQueueProtocol)
@protocol RiveCommandQueueProtocol

/**
 * Returns the next available request ID for correlating commands with
 * responses.
 *
 * Request IDs are used to match asynchronous command submissions with their
 * corresponding listener callbacks. Each call returns a unique ID that should
 * be used for a single command operation.
 *
 * @return A unique request ID
 */
@property(nonatomic, readonly) uint64_t nextRequestID;

- (void)start;
- (void)stop;

#pragma mark - Server

/**
 * Disconnects from the command server.
 */
- (void)disconnect;

#pragma mark - File

/**
 * Loads a Rive file into the command queue.
 *
 * @param data The binary data of the Rive file to load
 * @return A unique file handle identifier that can be used for subsequent
 * operations
 * @note The file handle is only valid for the lifetime of the loaded file.
 *       Once the file is deleted using deleteFile:, the handle becomes invalid.
 */
- (uint64_t)loadFile:(NSData*)data
            observer:(id<RiveFileListener>)observer
           requestID:(uint64_t)requestID;

/**
 * Deletes a previously loaded Rive file.
 *
 * @param file The file handle of the file to delete
 * @note This operation will also delete all artboards that were instantiated
 *       from this file.
 */
- (void)deleteFile:(uint64_t)file requestID:(uint64_t)requestID;

/**
 * Requests artboard names for a loaded file.
 *
 * @param fileHandle The file handle of the file to query
 * @param requestID The request ID for this operation
 * @note The response will be delivered via the file listener observer's
 *       onArtboardsListed:requestID:names: method
 */
- (void)requestArtboardNames:(uint64_t)fileHandle requestID:(uint64_t)requestID;

/**
 * Requests the names of all view models defined in a Rive file.
 *
 * @param fileHandle The file handle of the file to query
 * @param requestID The request ID for this operation
 * @note The response will be delivered via the file listener observer's
 *       onViewModelsListed:requestID:names: method
 */
- (void)requestViewModelNames:(uint64_t)fileHandle
                    requestID:(uint64_t)requestID;

/**
 * Requests the enum definitions for all enums defined in a Rive file.
 *
 * @param fileHandle The file handle of the file to query
 * @param requestID The request ID for this operation
 * @note The response will be delivered via the file listener observer's
 *       onViewModelEnumsListed:requestID:enums: method
 */
- (void)requestViewModelEnums:(uint64_t)fileHandle
                    requestID:(uint64_t)requestID;

/**
 * Requests the names of all view model instances for a specific view model.
 *
 * @param fileHandle The file handle of the file to query
 * @param viewModelName The name of the view model to query
 * @param requestID The request ID for this operation
 * @note The response will be delivered via the file listener observer's
 *       onViewModelInstanceNamesListed:requestID:viewModelName:names: method
 */
- (void)requestViewModelInstanceNames:(uint64_t)fileHandle
                        viewModelName:(NSString*)viewModelName
                            requestID:(uint64_t)requestID;

/**
 * Requests the property definitions for a specific view model.
 *
 * @param fileHandle The file handle of the file to query
 * @param viewModelName The name of the view model to query
 * @param requestID The request ID for this operation
 * @note The response will be delivered via the file listener observer's
 *       onViewModelPropertiesListed:requestID:viewModelName:properties: method
 */
- (void)requestViewModelPropertyDefinitions:(uint64_t)fileHandle
                              viewModelName:(NSString*)viewModelName
                                  requestID:(uint64_t)requestID;

/**
 * Creates the default artboard for a file.
 *
 * @param fileHandle The file handle of the file
 * @return The artboard handle of the created artboard
 */
- (uint64_t)createDefaultArtboardFromFile:(uint64_t)fileHandle
                                 observer:(id<RiveArtboardListener>)observer
                                requestID:(uint64_t)requestID;

/**
 * Creates an artboard with the specified name for a file.
 *
 * @param fileHandle The file handle of the file
 * @param name The name of the artboard to create
 * @return The artboard handle of the created artboard
 */
- (uint64_t)createArtboardNamed:(NSString*)name
                       fromFile:(uint64_t)fileHandle
                       observer:(id<RiveArtboardListener>)observer
                      requestID:(uint64_t)requestID;

/**
 * Deletes a previously created artboard.
 *
 * This method removes an artboard via the command queue and frees all
 * associated resources. After deletion, the artboard handle becomes invalid
 * and should not be used for any further operations.
 *
 * @param artboard The artboard handle of the artboard to delete
 * @note This operation is irreversible. Once an artboard is deleted, it
 *       cannot be recovered and all references to it become invalid.
 */
- (void)deleteArtboard:(uint64_t)artboard requestID:(uint64_t)requestID;

/**
 * Sets the size of an artboard.
 *
 * This method sets the width and height of the specified artboard. The width
 * and height are in display coordinates and will be divided by the scale factor
 * to get the logical artboard size.
 *
 * @param artboardHandle The artboard handle of the artboard to resize
 * @param width The width in display coordinates
 * @param height The height in display coordinates
 * @param scale The display scale factor (default: 1.0)
 * @param requestID The request ID for this operation
 */
- (void)setArtboardSize:(uint64_t)artboardHandle
                  width:(float)width
                 height:(float)height
                  scale:(float)scale
              requestID:(uint64_t)requestID;

/**
 * Resets the artboard size to its original dimensions.
 *
 * This method restores the artboard to its original size as defined in the
 * Rive file.
 *
 * @param artboardHandle The artboard handle of the artboard to reset
 * @param requestID The request ID for this operation
 */
- (void)resetArtboardSize:(uint64_t)artboardHandle
                requestID:(uint64_t)requestID;

/**
 * Requests the names of all state machines available on an artboard.
 *
 * This method initiates an asynchronous request to retrieve the names of
 * state machines that are available on the specified artboard. The response
 * will be delivered via the artboard listener observer's
 * onStateMachineNamesListed:names:requestID: method.
 *
 * @param artboardHandle The artboard handle of the artboard to query
 * @param requestID The unique request ID for this operation
 * @note The response will be delivered via the artboard listener observer's
 *       onStateMachineNamesListed:names:requestID: method. The request ID
 *       should be used to correlate the response with this request.
 */
- (void)requestStateMachineNames:(uint64_t)artboardHandle
                       requestID:(uint64_t)requestID;

/**
 * Requests the default view model information for an artboard.
 *
 * This method initiates an asynchronous request to retrieve the default view
 * model name and instance name for the specified artboard. The response will be
 * delivered via the artboard listener observer's
 * onDefaultViewModelInfoReceived:requestID:viewModelName:instanceName: method.
 *
 * @param artboardHandle The artboard handle of the artboard to query
 * @param fileHandle The file handle of the file containing the artboard
 * @param requestID The unique request ID for this operation
 * @note The response will be delivered via the artboard listener observer's
 *       onDefaultViewModelInfoReceived:requestID:viewModelName:instanceName:
 * method. The request ID should be used to correlate the response with this
 * request.
 */
- (void)requestDefaultViewModelInfo:(uint64_t)artboardHandle
                           fromFile:(uint64_t)fileHandle
                          requestID:(uint64_t)requestID;

/**
 * Creates the default state machine for an artboard.
 *
 * This method creates the default (first) state machine from the specified
 * artboard. It delegates to the command queue and returns a handle that
 * uniquely identifies the created state machine.
 *
 * @param artboardHandle The artboard handle of the artboard that owns the state
 * machine
 * @return The state machine handle of the created state machine
 */
- (uint64_t)createDefaultStateMachineFromArtboard:(uint64_t)artboardHandle
                                        requestID:(uint64_t)requestID;
;

/**
 * Creates a state machine with the specified name for an artboard.
 *
 * This method creates a state machine with the given name from the specified
 * artboard. It delegates to the command queue and returns a handle that
 * uniquely identifies the created state machine.
 *
 * @param name The name of the state machine to create
 * @param artboardHandle The artboard handle of the artboard that owns the state
 * machine
 * @return The state machine handle of the created state machine
 */
- (uint64_t)createStateMachineNamed:(NSString*)name
                       fromArtboard:(uint64_t)artboardHandle
                          requestID:(uint64_t)requestID;

/**
 * Advances a state machine by the specified time interval.
 *
 * @param stateMachineHandle The handle of the state machine to advance
 * @param time The time interval in seconds to advance the state machine
 * @param requestID The request ID for this operation
 * @note This operation is typically called every frame. The time should
 *       represent the delta since the last advance call.
 */
- (void)advanceStateMachine:(uint64_t)stateMachineHandle
                         by:(NSTimeInterval)time
                  requestID:(uint64_t)requestID;

/**
 * Deletes a previously created state machine.
 *
 * This method removes a state machine and frees all associated resources.
 * After deletion, the state machine handle becomes invalid and should not
 * be used for any further operations.
 *
 * @param stateMachineHandle The handle of the state machine to delete
 * @param requestID The request ID for this operation
 * @note This operation is irreversible. Once a state machine is deleted,
 *       it cannot be recovered.
 */
- (void)deleteStateMachine:(uint64_t)stateMachineHandle
                 requestID:(uint64_t)requestID;

/**
 * Binds a view model instance to a state machine for data binding.
 *
 * @param stateMachineHandle The handle of the state machine to bind
 * @param viewModelInstanceHandle The handle of the view model instance to bind
 * @param requestID The request ID for this operation
 * @note Only one view model instance can be bound to a state machine at a time.
 *       Binding a new instance will replace any previously bound instance.
 */
- (void)bindViewModelInstance:(uint64_t)stateMachineHandle
          toViewModelInstance:(uint64_t)viewModelInstanceHandle
                    requestID:(uint64_t)requestID;

#pragma mark - Pointer Events

/**
 * Sends a pointer move event to a state machine.
 *
 * @param stateMachineHandle The handle of the state machine to receive the
 * event
 * @param position The cursor position in screen coordinates
 * @param screenBounds The bounds of the coordinate system of the cursor
 * @param fit The fit the artboard is drawn with
 * @param alignment The alignment the artboard is drawn with
 * @param scaleFactor Scale factor for things like retina display (default: 1.0)
 * @param requestID The request ID for this operation
 */
- (void)pointerMove:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID;

/**
 * Sends a pointer down event to a state machine.
 *
 * @param stateMachineHandle The handle of the state machine to receive the
 * event
 * @param position The cursor position in screen coordinates
 * @param screenBounds The bounds of the coordinate system of the cursor
 * @param fit The fit the artboard is drawn with
 * @param alignment The alignment the artboard is drawn with
 * @param scaleFactor Scale factor for things like retina display (default: 1.0)
 * @param requestID The request ID for this operation
 */
- (void)pointerDown:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID;

/**
 * Sends a pointer up event to a state machine.
 *
 * @param stateMachineHandle The handle of the state machine to receive the
 * event
 * @param position The cursor position in screen coordinates
 * @param screenBounds The bounds of the coordinate system of the cursor
 * @param fit The fit the artboard is drawn with
 * @param alignment The alignment the artboard is drawn with
 * @param scaleFactor Scale factor for things like retina display (default: 1.0)
 * @param requestID The request ID for this operation
 */
- (void)pointerUp:(uint64_t)stateMachineHandle
         position:(CGPoint)position
     screenBounds:(CGSize)screenBounds
              fit:(RiveConfigurationFit)fit
        alignment:(RiveConfigurationAlignment)alignment
      scaleFactor:(float)scaleFactor
        requestID:(uint64_t)requestID;

/**
 * Sends a pointer exit event to a state machine.
 *
 * @param stateMachineHandle The handle of the state machine to receive the
 * event
 * @param position The cursor position in screen coordinates
 * @param screenBounds The bounds of the coordinate system of the cursor
 * @param fit The fit the artboard is drawn with
 * @param alignment The alignment the artboard is drawn with
 * @param scaleFactor Scale factor for things like retina display (default: 1.0)
 * @param requestID The request ID for this operation
 */
- (void)pointerExit:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID;

#pragma mark - Drawing

/**
 * Creates a unique draw key for coordinating drawing operations.
 *
 * @return A unique draw key identifier
 * @note Draw keys should be created on the main thread and used immediately
 *       with draw:callback:. They are not meant to be stored or reused.
 */
- (uint64_t)createDrawKey;

/**
 * Queues a drawing operation with a callback that receives the renderer.
 *
 * This method schedules a drawing operation that will be executed when the
 * command server processes drawing commands. The callback receives a pointer
 * to the C++ renderer object, which can be used to draw the artboard.
 *
 * The captured object parameter allows you to retain Objective-C objects that
 * need to stay alive during the drawing operation. The finalize block is called
 * after drawing completes and can be used to commit command buffers or perform
 * cleanup.
 *
 * @param drawKey A unique draw key created with createDrawKey
 * @param callback A block that receives the C++ renderer pointer (void*) and
 *                 performs the actual drawing. This block is called on the
 *                 background thread where the command server processes
 * commands.
 * @note The renderer pointer in the callback is only valid during the execution
 *       of the callback block. Do not store it for later use.
 */
- (void)draw:(uint64_t)drawKey callback:(void (^)(void*))callback;

#pragma mark - Data Binding

/**
 * Creates a blank view model instance for an artboard's default view model.
 *
 * @param artboardHandle The artboard handle to get the default view model from
 * @param fileHandle The file handle containing the artboard
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)
    createBlankViewModelInstanceForArtboard:(uint64_t)artboardHandle
                                   fromFile:(uint64_t)fileHandle
                                   observer:(id<RiveViewModelInstanceListener>)
                                                observer
                                  requestID:(uint64_t)requestID;

/**
 * Creates a blank view model instance for a named view model.
 *
 * @param viewModelName The name of the view model type to instantiate
 * @param fileHandle The file handle containing the view model definition
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)createBlankViewModelInstanceNamed:(NSString*)viewModelName
                                     fromFile:(uint64_t)fileHandle
                                     observer:
                                         (id<RiveViewModelInstanceListener>)
                                             observer
                                    requestID:(uint64_t)requestID;

/**
 * Creates a view model instance with default values from an artboard.
 *
 * @param artboardHandle The artboard handle to get the default view model from
 * @param fileHandle The file handle containing the artboard
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)
    createDefaultViewModelInstanceForArtboard:(uint64_t)artboardHandle
                                     fromFile:(uint64_t)fileHandle
                                     observer:
                                         (id<RiveViewModelInstanceListener>)
                                             observer
                                    requestID:(uint64_t)requestID;

/**
 * Creates a view model instance with default values from a named view model.
 *
 * @param viewModelName The name of the view model type to instantiate
 * @param fileHandle The file handle containing the view model definition
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)createDefaultViewModelInstanceNamed:(NSString*)viewModelName
                                       fromFile:(uint64_t)fileHandle
                                       observer:
                                           (id<RiveViewModelInstanceListener>)
                                               observer
                                      requestID:(uint64_t)requestID;

/**
 * Creates a view model instance by name from an artboard's view models.
 *
 * @param instanceName The name of the instance to create (as defined in the
 * file)
 * @param artboardHandle The artboard handle containing the instance definition
 * @param fileHandle The file handle containing the artboard
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)createViewModelInstanceNamed:(NSString*)instanceName
                             forArtboard:(uint64_t)artboardHandle
                                fromFile:(uint64_t)fileHandle
                                observer:
                                    (id<RiveViewModelInstanceListener>)observer
                               requestID:(uint64_t)requestID;

/**
 * Creates a view model instance by name from a specific view model type.
 *
 * @param instanceName The name of the instance to create (as defined in the
 * file)
 * @param viewModelName The name of the view model type
 * @param fileHandle The file handle containing the view model and instance
 * @param observer The listener that will receive property updates
 * @param requestID The request ID for this operation
 * @return A view model instance handle (may be 0 if creation fails)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method
 */
- (uint64_t)createViewModelInstanceNamed:(NSString*)instanceName
                           viewModelName:(NSString*)viewModelName
                                fromFile:(uint64_t)fileHandle
                                observer:
                                    (id<RiveViewModelInstanceListener>)observer
                               requestID:(uint64_t)requestID;

/**
 * Requests the current string value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "title" or "user.name")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type string. Use requestViewModelInstanceEnum:
 *       for enum properties that return string values.
 */
- (void)requestViewModelInstanceString:(uint64_t)viewModelInstanceHandle
                                  path:(NSString*)path
                             requestID:(uint64_t)requestID;

/**
 * Requests the current number value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "score" or "position.x")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type number or integer.
 */
- (void)requestViewModelInstanceNumber:(uint64_t)viewModelInstanceHandle
                                  path:(NSString*)path
                             requestID:(uint64_t)requestID;

/**
 * Requests the current boolean value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "isEnabled" or "settings.autoSave")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type boolean.
 */
- (void)requestViewModelInstanceBool:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                           requestID:(uint64_t)requestID;

/**
 * Requests the current color value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "backgroundColor")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type color. The color is returned as a 32-bit
 *       ARGB integer where each component is 8 bits (A in bits 31-24,
 *       R in bits 23-16, G in bits 15-8, B in bits 7-0).
 */
- (void)requestViewModelInstanceColor:(uint64_t)viewModelInstanceHandle
                                 path:(NSString*)path
                            requestID:(uint64_t)requestID;

/**
 * Requests the current enum value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "status" or "user.role")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type enum. The enum value is returned as a
 * string.
 */
- (void)requestViewModelInstanceEnum:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                           requestID:(uint64_t)requestID;

/**
 * Requests the size (element count) of a list property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path to the list (e.g., "items" or "users.friends")
 * @param requestID The request ID for correlating the response
 * @note The property must be of type list.
 */
- (void)requestViewModelInstanceListSize:(uint64_t)viewModelInstanceHandle
                                    path:(NSString*)path
                               requestID:(uint64_t)requestID;

/**
 * Requests the name of a view model instance.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param requestID The request ID for correlating the response
 */
- (void)requestViewModelInstanceName:(uint64_t)viewModelInstanceHandle
                           requestID:(uint64_t)requestID;

/**
 * Sets the string value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "title" or "user.name")
 * @param value The new string value
 * @param requestID The request ID for this operation
 * @note The property must be of type string. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceString:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             value:(NSString*)value
                         requestID:(uint64_t)requestID;

/**
 * Sets the number value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "score" or "position.x")
 * @param value The new number value
 * @param requestID The request ID for this operation
 * @note The property must be of type number. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceNumber:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             value:(float)value
                         requestID:(uint64_t)requestID;

/**
 * Sets the boolean value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "isEnabled" or "settings.autoSave")
 * @param value The new boolean value
 * @param requestID The request ID for this operation
 * @note The property must be of type boolean. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceBool:(uint64_t)viewModelInstanceHandle
                            path:(NSString*)path
                           value:(BOOL)value
                       requestID:(uint64_t)requestID;

/**
 * Sets the color value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "backgroundColor")
 * @param value The new color value as a 32-bit ARGB integer
 * @param requestID The request ID for this operation
 * @note The property must be of type color. The color should be a 32-bit ARGB
 *       integer where each component is 8 bits (A in bits 31-24, R in bits
 *       23-16, G in bits 15-8, B in bits 7-0). Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceColor:(uint64_t)viewModelInstanceHandle
                             path:(NSString*)path
                            value:(uint32_t)value
                        requestID:(uint64_t)requestID;

/**
 * Sets the enum value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "status" or "user.role")
 * @param value The new enum value as a string
 * @param requestID The request ID for this operation
 * @note The property must be of type enum. The value must match one of the
 *       enum's defined values. Changes are applied asynchronously.
 */
- (void)setViewModelInstanceEnum:(uint64_t)viewModelInstanceHandle
                            path:(NSString*)path
                           value:(NSString*)value
                       requestID:(uint64_t)requestID;

/**
 * Sets the image value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "avatar" or "user.profilePicture")
 * @param value The handle of a decoded image
 * @param requestID The request ID for this operation
 * @note The property must be of type assetImage. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceImage:(uint64_t)viewModelInstanceHandle
                             path:(NSString*)path
                            value:(uint64_t)value
                        requestID:(uint64_t)requestID;

/**
 * Sets the artboard value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "nestedArtboard")
 * @param value The handle of a created artboard
 * @param requestID The request ID for this operation
 * @note The property must be of type artboard. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceArtboard:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                               value:(uint64_t)value
                           requestID:(uint64_t)requestID;

/**
 * Sets a nested view model instance value of a view model property.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path (e.g., "user" or "settings.theme")
 * @param value The handle of a created view model instance
 * @param requestID The request ID for this operation
 * @note The property must be of type viewModel. Changes are applied
 * asynchronously.
 */
- (void)setViewModelInstanceNestedViewModel:(uint64_t)viewModelInstanceHandle
                                       path:(NSString*)path
                                      value:(uint64_t)value
                                  requestID:(uint64_t)requestID;

/**
 * Fires a trigger property in a view model instance.
 *
 * @param viewModelInstanceHandle The handle of the view model instance
 * @param path The property path to the trigger (e.g., "buttonClicked")
 * @param requestID The request ID for this operation
 * @note The property must be of type trigger. Triggers are automatically reset
 *       after being fired.
 */
- (void)fireViewModelTrigger:(uint64_t)viewModelInstanceHandle
                        path:(NSString*)path
                   requestID:(uint64_t)requestID;

/**
 * Creates a reference to a nested view model instance property.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the nested view model (e.g., "user" or
 * "settings.theme")
 * @param observer The listener that will receive property updates for the
 * nested instance
 * @param requestID The request ID for this operation
 * @return A view model instance handle for the nested instance (may be 0 if not
 * found)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method. The handle remains
 * valid as long as the parent instance exists.
 */
- (uint64_t)
    referenceNestedViewModelInstance:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                            observer:(id<RiveViewModelInstanceListener>)observer
                           requestID:(uint64_t)requestID;

/**
 * Creates a reference to a view model instance in a list property.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items" or "users.friends")
 * @param index The zero-based index of the element in the list
 * @param observer The listener that will receive property updates for the
 * element
 * @param requestID The request ID for this operation
 * @return A view model instance handle for the list element (may be 0 if index
 * is invalid)
 * @note The instance handle is delivered asynchronously via the observer's
 *       onViewModelDataReceived:requestID:data: method. The handle remains
 * valid as long as the element exists in the list.
 */
- (uint64_t)
    referenceListViewModelInstance:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             index:(int)index
                          observer:(id<RiveViewModelInstanceListener>)observer
                         requestID:(uint64_t)requestID;

/**
 * Appends a view model instance to a list property.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items")
 * @param value The handle of the view model instance to append
 * @param requestID The request ID for this operation
 * @note The property must be of type list. Changes are applied asynchronously.
 */
- (void)appendViewModelInstanceListViewModel:(uint64_t)viewModelInstanceHandle
                                        path:(NSString*)path
                                       value:(uint64_t)value
                                   requestID:(uint64_t)requestID;

/**
 * Inserts a view model instance into a list property at a specific index.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items")
 * @param value The handle of the view model instance to insert
 * @param index The zero-based index where to insert the element
 * @param requestID The request ID for this operation
 * @note The property must be of type list. The index must be between 0 and
 *       the current list size (inclusive). Changes are applied asynchronously.
 */
- (void)insertViewModelInstanceListViewModel:(uint64_t)viewModelInstanceHandle
                                        path:(NSString*)path
                                       value:(uint64_t)value
                                       index:(int)index
                                   requestID:(uint64_t)requestID;

/**
 * Removes a view model instance from a list property by index.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items")
 * @param index The zero-based index of the element to remove
 * @param value The handle of the view model instance being removed (for
 * validation)
 * @param requestID The request ID for this operation
 * @note The property must be of type list. Changes are applied asynchronously.
 */
- (void)removeViewModelInstanceListViewModelAtIndex:
            (uint64_t)viewModelInstanceHandle
                                               path:(NSString*)path
                                              index:(int)index
                                              value:(uint64_t)value
                                          requestID:(uint64_t)requestID
    NS_SWIFT_NAME(removeViewModelInstanceListViewModelAtIndex(_:path:index:value:requestID:));

/**
 * Removes a view model instance from a list property by value.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items")
 * @param value The handle of the view model instance to remove
 * @param requestID The request ID for this operation
 * @note The property must be of type list. Changes are applied asynchronously.
 */
- (void)removeViewModelInstanceListViewModelByValue:
            (uint64_t)viewModelInstanceHandle
                                               path:(NSString*)path
                                              value:(uint64_t)value
                                          requestID:(uint64_t)requestID
    NS_SWIFT_NAME(removeViewModelInstanceListViewModelByValue(_:path:value:requestID:));

/**
 * Swaps two elements in a list property by their indices.
 *
 * @param viewModelInstanceHandle The handle of the parent view model instance
 * @param path The property path to the list (e.g., "items")
 * @param atIndex The zero-based index of the first element
 * @param withIndex The zero-based index of the second element
 * @param requestID The request ID for this operation
 * @note The property must be of type list. Changes are applied asynchronously.
 */
- (void)swapViewModelInstanceListValues:(uint64_t)viewModelInstanceHandle
                                   path:(NSString*)path
                                atIndex:(int)atIndex
                              withIndex:(int)withIndex
                              requestID:(uint64_t)requestID
    NS_SWIFT_NAME(swapViewModelInstanceListValues(_:path:atIndex:withIndex:requestID:));

/**
 * Deletes a view model instance and frees its resources.
 *
 * @param viewModelInstance The handle of the view model instance to delete
 * @param requestID The request ID for this operation
 * @note This operation is irreversible. Make sure to unbind the instance from
 *       any state machines before deleting it.
 */
- (void)deleteViewModelInstance:(uint64_t)viewModelInstance
                      requestID:(uint64_t)requestID;

/**
 * Subscribes to property change notifications for a view model property.
 *
 * @param viewModelInstance The handle of the view model instance
 * @param path The property path to subscribe to (e.g., "title" or "user.name")
 * @param type The expected data type of the property
 * @param requestID The request ID for this operation
 * @note You must provide the same observer that was used when creating the
 *       view model instance. Subscriptions remain active until you unsubscribe
 *       or the instance is deleted.
 */
- (void)subscribeToViewModelProperty:(uint64_t)viewModelInstance
                                path:(NSString*)path
                                type:(RiveViewModelInstanceDataType)type
                           requestID:(uint64_t)requestID;

/**
 * Unsubscribes from property change notifications for a view model property.
 *
 * @param viewModelInstance The handle of the view model instance
 * @param path The property path to unsubscribe from (e.g., "title")
 * @param type The data type of the property (must match the subscription)
 * @param requestID The request ID for this operation
 * @note The type parameter must match the type used when subscribing.
 */
- (void)unsubscribeToViewModelProperty:(uint64_t)viewModelInstance
                                  path:(NSString*)path
                                  type:(RiveViewModelInstanceDataType)type
                             requestID:(uint64_t)requestID;

#pragma mark - RenderImage

/**
 * Decodes image data and creates a render image resource.
 *
 * @param data The image data to decode
 * @param listener The listener that will receive decode completion
 * notifications
 * @param requestID The request ID for correlating the response
 * @return A temporary handle (the actual handle is delivered via the listener)
 * @note The image handle is delivered via the listener's
 *       onRenderImageDecoded:requestID: method. If decoding fails,
 *       onRenderImageError:requestID:message: is called instead.
 */
- (uint64_t)decodeImage:(NSData*)data
               listener:(id<RiveRenderImageListener>)listener
              requestID:(uint64_t)requestID;

/**
 * Deletes a previously decoded render image.
 *
 * This frees the image resources. After deletion, the image handle becomes
 * invalid and should not be used for any further operations.
 *
 * @param renderImage The handle of the image to delete
 * @param requestID The request ID for this operation
 * @note This operation is irreversible. Make sure to remove the image from
 *       any global assets before deleting it.
 */
- (void)deleteImage:(uint64_t)renderImage requestID:(uint64_t)requestID;

/**
 * Adds a decoded image as a global asset that can be referenced by name.
 *
 * @param name The asset name to use (must match the name in the Rive file)
 * @param imageHandle The handle of the decoded image
 * @param requestID The request ID for this operation
 * @note If an asset with the same name already exists, it will be replaced.
 */
- (void)addGlobalImageAsset:(NSString*)name
                imageHandle:(uint64_t)imageHandle
                  requestID:(uint64_t)requestID;

/**
 * Removes a global image asset by name.
 *
 * After removal, the asset name will no longer resolve to the image. The
 * image itself is not deleted; use deleteImage:requestID: to free the image
 * resources if needed.
 *
 * @param name The asset name to remove
 * @param requestID The request ID for this operation
 */
- (void)removeGlobalImageAsset:(NSString*)name requestID:(uint64_t)requestID;

#pragma mark - Font

/**
 * Decodes font data and creates a font resource.
 *
 * @param data The font data to decode
 * @param listener The listener that will receive decode completion
 * notifications
 * @param requestID The request ID for correlating the response
 * @return A temporary handle (the actual handle is delivered via the listener)
 * @note The font handle is delivered via the listener's
 *       onFontDecoded:requestID: method. If decoding fails,
 *       onFontError:requestID:message: is called instead.
 */
- (uint64_t)decodeFont:(NSData*)data
              listener:(id<RiveFontListener>)listener
             requestID:(uint64_t)requestID;

/**
 * Deletes a previously decoded font.
 *
 * This frees the font resources. After deletion, the font handle becomes
 * invalid and should not be used for any further operations.
 *
 * @param font The handle of the font to delete
 * @param requestID The request ID for this operation
 * @note This operation is irreversible. Make sure to remove the font from
 *       any global assets before deleting it.
 */
- (void)deleteFont:(uint64_t)font requestID:(uint64_t)requestID;

/**
 * Adds a decoded font as a global asset that can be referenced by name.
 *
 * @param name The asset name to use (must match the name in the Rive file)
 * @param fontHandle The handle of the decoded font
 * @param requestID The request ID for this operation
 * @note If an asset with the same name already exists, it will be replaced.
 */
- (void)addGlobalFontAsset:(NSString*)name
                fontHandle:(uint64_t)fontHandle
                 requestID:(uint64_t)requestID;

/**
 * Removes a global font asset by name.
 *
 * After removal, the asset name will no longer resolve to the font. The font
 * itself is not deleted; use deleteFont:requestID: to free the font resources
 * if needed.
 *
 * @param name The asset name to remove
 * @param requestID The request ID for this operation
 */
- (void)removeGlobalFontAsset:(NSString*)name requestID:(uint64_t)requestID;

#pragma mark - Audio

/**
 * Decodes audio data and creates an audio resource.
 *
 * @param data The audio data to decode
 * @param listener The listener that will receive decode completion
 * notifications
 * @param requestID The request ID for correlating the response
 * @return A temporary handle (the actual handle is delivered via the listener)
 * @note The audio handle is delivered via the listener's
 *       onAudioSourceDecoded:requestID: method. If decoding fails,
 *       onAudioSourceError:requestID:message: is called instead.
 */
- (uint64_t)decodeAudio:(NSData*)data
               listener:(id<RiveAudioListener>)listener
              requestID:(uint64_t)requestID;

/**
 * Deletes a previously decoded audio resource.
 *
 * This frees the audio resources. After deletion, the audio handle becomes
 * invalid and should not be used for any further operations.
 *
 * @param audio The handle of the audio to delete
 * @param requestID The request ID for this operation
 * @note This operation is irreversible. Make sure to remove the audio from
 *       any global assets before deleting it.
 */
- (void)deleteAudio:(uint64_t)audio requestID:(uint64_t)requestID;

/**
 * Adds a decoded audio as a global asset that can be referenced by name.
 *
 * @param name The asset name to use (must match the name in the Rive file)
 * @param audioHandle The handle of the decoded audio
 * @param requestID The request ID for this operation
 * @note If an asset with the same name already exists, it will be replaced.
 */
- (void)addGlobalAudioAsset:(NSString*)name
                audioHandle:(uint64_t)audioHandle
                  requestID:(uint64_t)requestID;

/**
 * Removes a global audio asset by name.
 *
 * After removal, the asset name will no longer resolve to the audio. The audio
 * itself is not deleted; use deleteAudio:requestID: to free the audio resources
 * if needed.
 *
 * @param name The asset name to remove
 * @param requestID The request ID for this operation
 */
- (void)removeGlobalAudioAsset:(NSString*)name requestID:(uint64_t)requestID;

@end

@class RiveCommandQueue;

/**
 * @class RiveCommandQueue
 *
 * A concrete implementation of RiveCommandQueueProtocol that manages the
 * lifecycle and execution of Rive commands.
 *
 * This class wraps a C++ command queue and provides thread-safe access from
 * Objective-C/Swift. Commands are queued on the main thread and processed
 * asynchronously by a RiveCommandServer running on a background thread.
 *
 * The queue maintains handles for all resources (files, artboards, state
 * machines, etc.) and ensures proper cleanup when resources are deleted.
 * All operations use request IDs for correlation with asynchronous responses.
 */
NS_SWIFT_NAME(CommandQueue)
@interface RiveCommandQueue : NSObject <RiveCommandQueueProtocol>

@end

NS_ASSUME_NONNULL_END

#endif /* RiveCommandQueue_h */
