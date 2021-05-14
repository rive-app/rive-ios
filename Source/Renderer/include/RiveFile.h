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

/*
 * RiveFile
 */
@interface RiveFile : NSObject

@property (class, readonly) uint majorVersion;
@property (class, readonly) uint minorVersion;

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length;

// Returns a reference to the default artboard
- (RiveArtboard *)artboard;

// Returns the number of artboards in the file
- (NSInteger)artboardCount;

// Returns the artboard by its index
- (RiveArtboard *)artboardFromIndex:(NSInteger)index;

// Returns the artboard by its name
- (RiveArtboard *)artboardFromName:(NSString *)name;

// Returns the names of all artboards in the file.
- (NSArray<NSString *> *)artboardNames;


@end

NS_ASSUME_NONNULL_END

#endif /* rive_file_h */
