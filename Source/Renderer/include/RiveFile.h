//
//  RiveFile.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef rive_file_h
#define rive_file_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveArtboard;
@protocol RiveFileDelegate;
@class RiveFileAsset;
@class RiveFactory;
@class RiveDataBindingViewModel;
@class RiveBindableArtboard;
typedef bool (^LoadAsset)(RiveFileAsset* asset,
                          NSData* data,
                          RiveFactory* factory);

/*
 * RiveFile
 */
@interface RiveFile : NSObject

@property(class, readonly) uint majorVersion;
@property(class, readonly) uint minorVersion;

/// Is the Rive file loaded and ready for use?
@property bool isLoaded;

/// Delegate for calling when a file has finished loading
@property(weak) id delegate;

/// The number of view models in the file.
@property(nonatomic, readonly) NSUInteger viewModelCount;

/// Used to manage url sessions Rive, this is to enable testing.
- (nullable instancetype)initWithByteArray:(NSArray*)bytes
                                   loadCdn:(bool)cdn
                                     error:(NSError**)error;
- (nullable instancetype)initWithByteArray:(NSArray*)bytes
                                   loadCdn:(bool)cdn
                         customAssetLoader:(LoadAsset)customAssetLoader
                                     error:(NSError**)error;

- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                                 error:(NSError**)error;
- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                     customAssetLoader:(LoadAsset)customAssetLoader
                                 error:(NSError**)error;

- (nullable instancetype)initWithData:(NSData*)bytes
                              loadCdn:(bool)cdn
                                error:(NSError**)error;
- (nullable instancetype)initWithData:(NSData*)bytes
                              loadCdn:(bool)cdn
                    customAssetLoader:(LoadAsset)customAssetLoader
                                error:(NSError**)error;

- (nullable instancetype)initWithResource:(NSString*)resourceName
                            withExtension:(NSString*)extension
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error;
- (nullable instancetype)initWithResource:(NSString*)resourceName
                            withExtension:(NSString*)extension
                                  loadCdn:(bool)cdn
                        customAssetLoader:(LoadAsset)customAssetLoader
                                    error:(NSError**)error;

- (nullable instancetype)initWithResource:(NSString*)resourceName
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error;
- (nullable instancetype)initWithResource:(NSString*)resourceName
                                  loadCdn:(bool)cdn
                        customAssetLoader:(LoadAsset)customAssetLoader
                                    error:(NSError**)error;

- (nullable instancetype)initWithHttpUrl:(NSString*)url
                                 loadCdn:(bool)cdn
                            withDelegate:(id<RiveFileDelegate>)delegate;
- (nullable instancetype)initWithHttpUrl:(NSString*)url
                                 loadCdn:(bool)cdn
                       customAssetLoader:(LoadAsset)customAssetLoader
                            withDelegate:(id<RiveFileDelegate>)delegate;

/// Returns a reference to the default artboard
- (RiveArtboard* __nullable)artboard:(NSError**)error;

/// Returns the number of artboards in the file
- (NSInteger)artboardCount;

/// Returns the artboard by its index
- (RiveArtboard* __nullable)artboardFromIndex:(NSInteger)index
                                        error:(NSError**)error;

/// Returns the artboard by its name
- (RiveArtboard* __nullable)artboardFromName:(NSString*)name
                                       error:(NSError**)error;

/// Returns the names of all artboards in the file.
- (NSArray<NSString*>*)artboardNames;

#pragma mark - Data Binding

/// Returns a view model from the file by index.
///
/// The index of a view model starts at 0, where 0 is the first view model
/// listed in the editor's "Data" panel from top-to-bottom.
///
/// Unlike `RiveDataBindingViewModel.Instance`, a strong reference to this model
/// does not have to be made.
///
/// - Parameter index: The index of the view model.
///
/// - Returns: A view model if one exists by index, otherwise nil.
- (nullable RiveDataBindingViewModel*)viewModelAtIndex:(NSUInteger)index;

/// Returns a view model from the file by name.
///
/// The name of the view model has to match the name of a view model in the
/// editor's "Data" panel.
///
/// Unlike `RiveDataBindingViewModel.Instance`, a strong reference to this model
/// does not have to be made.
///
/// - Parameter name: The name of the view model.
///
/// - Returns: A view model if one exists by name, otherwise nil.
- (nullable RiveDataBindingViewModel*)viewModelNamed:(nonnull NSString*)name;

/// Returns the default view model for an artboard.
///
/// The default view model is the view model selected under the "Data Bind"
/// panel for an artboard.
///
/// Unlike `RiveDataBindingViewModel.Instance`, a strong reference to this model
/// does not have to be made.
///
/// - Parameter artboard: The artboard within the `RiveFile` that contains a
/// data binding view model.
///
/// - Returns: A view model if one exists for the artboard, otherwise nil.
- (nullable RiveDataBindingViewModel*)defaultViewModelForArtboard:
    (RiveArtboard*)artboard;

/// Returns a bindable artboard from the file by its index.
///
/// A bindable artboard is an artboard that can be used with data binding
/// features. The index of an artboard starts at 0, where 0 is the first
/// artboard in the file.
///
/// - Parameter index: The index of the artboard to retrieve.
/// - Parameter error: A pointer to an NSError object. If an error occurs, this
/// pointer will contain an error object describing the problem.
///
/// - Returns: A bindable artboard if one exists at the specified index,
/// otherwise nil.
- (nullable RiveBindableArtboard*)bindableArtboardAtIndex:(NSInteger)index
                                                    error:(NSError**)error;

/// Returns a bindable artboard from the file by its name.
///
/// A bindable artboard is an artboard that can be used with data binding
/// features. The name must match exactly with an artboard name in the Rive
/// file.
///
/// - Parameter name: The name of the artboard to retrieve. Must not be nil.
/// - Parameter error: A pointer to an NSError object. If an error occurs, this
/// pointer will contain an error object describing the problem.
///
/// - Returns: A bindable artboard if one exists with the specified name,
/// otherwise nil.
- (nullable RiveBindableArtboard*)bindableArtboardWithName:(NSString*)name
                                                     error:(NSError**)error;

@end

/*
 * Delegate to inform when a rive file is loaded
 */
@protocol RiveFileDelegate <NSObject>
- (BOOL)riveFileDidLoad:(RiveFile*)riveFile error:(NSError**)error;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_file_h */
