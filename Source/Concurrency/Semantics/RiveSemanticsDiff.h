//
//  RiveSemanticsDiff.h
//  RiveRuntime
//

#ifndef RiveSemanticsDiff_h
#define RiveSemanticsDiff_h

#import <Foundation/Foundation.h>
#import <RiveRuntime/RiveEnums.h>

NS_ASSUME_NONNULL_BEGIN

/// A single node's full semantic data as reported by the C++ runtime in an
/// incremental diff. Bridged to Swift as ``SemanticsDiffNode``.
NS_SWIFT_NAME(SemanticsDiffNode)
@interface RiveSemanticsDiffNode : NSObject

@property(nonatomic, readonly) uint32_t nodeID;
@property(nonatomic, readonly) RiveSemanticRole role;
@property(nonatomic, readonly, copy) NSString* label;
@property(nonatomic, readonly, copy) NSString* value;
@property(nonatomic, readonly, copy) NSString* hint;
@property(nonatomic, readonly) RiveSemanticState stateFlags;
@property(nonatomic, readonly) RiveSemanticTrait traitFlags;
@property(nonatomic, readonly) uint32_t headingLevel;
@property(nonatomic, readonly) float minX;
@property(nonatomic, readonly) float minY;
@property(nonatomic, readonly) float maxX;
@property(nonatomic, readonly) float maxY;
@property(nonatomic, readonly) int32_t parentID;
@property(nonatomic, readonly) uint32_t siblingIndex;

- (instancetype)initWithID:(uint32_t)nodeID
                      role:(RiveSemanticRole)role
                     label:(NSString*)label
                     value:(NSString*)value
                      hint:(NSString*)hint
                stateFlags:(RiveSemanticState)stateFlags
                traitFlags:(RiveSemanticTrait)traitFlags
              headingLevel:(uint32_t)headingLevel
                      minX:(float)minX
                      minY:(float)minY
                      maxX:(float)maxX
                      maxY:(float)maxY
                  parentID:(int32_t)parentID
              siblingIndex:(uint32_t)siblingIndex NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

/// A bounds-only update for the geometry hot path. Carries just the node ID
/// and its new bounding box, avoiding a full node payload.
NS_SWIFT_NAME(SemanticsBoundsUpdate)
@interface RiveSemanticsBoundsUpdate : NSObject

@property(nonatomic, readonly) uint32_t nodeID;
@property(nonatomic, readonly) float minX;
@property(nonatomic, readonly) float minY;
@property(nonatomic, readonly) float maxX;
@property(nonatomic, readonly) float maxY;

- (instancetype)initWithID:(uint32_t)nodeID
                      minX:(float)minX
                      minY:(float)minY
                      maxX:(float)maxX
                      maxY:(float)maxY NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

/// An updated ordered child list for a parent node. Replaces the parent's
/// entire children array (not a partial patch).
NS_SWIFT_NAME(SemanticsChildrenUpdate)
@interface RiveSemanticsChildrenUpdate : NSObject

@property(nonatomic, readonly) int32_t parentID;
@property(nonatomic, readonly, copy) NSArray<NSNumber*>* childIDs;

- (instancetype)initWithParentID:(int32_t)parentID
                        childIDs:(NSArray<NSNumber*>*)childIDs
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

/// An incremental semantic diff payload from the C++ runtime. Contains all
/// change categories (added, removed, moved, children updated, semantic
/// updates, and geometry updates) for a single frame.
NS_SWIFT_NAME(SemanticsDiff)
@interface RiveSemanticsDiff : NSObject

@property(nonatomic, readonly) uint64_t frameNumber;
@property(nonatomic, readonly) uint64_t treeVersion;
@property(nonatomic, readonly) uint32_t rootID;
@property(nonatomic, readonly, copy) NSArray<NSNumber*>* removed;
@property(nonatomic, readonly, copy) NSArray<RiveSemanticsDiffNode*>* added;
@property(nonatomic, readonly, copy) NSArray<RiveSemanticsDiffNode*>* moved;
@property(nonatomic, readonly, copy)
    NSArray<RiveSemanticsChildrenUpdate*>* childrenUpdated;
@property(nonatomic, readonly, copy)
    NSArray<RiveSemanticsDiffNode*>* updatedSemantic;
@property(nonatomic, readonly, copy)
    NSArray<RiveSemanticsBoundsUpdate*>* updatedGeometry;

- (instancetype)
    initWithFrameNumber:(uint64_t)frameNumber
            treeVersion:(uint64_t)treeVersion
                 rootID:(uint32_t)rootID
                removed:(NSArray<NSNumber*>*)removed
                  added:(NSArray<RiveSemanticsDiffNode*>*)added
                  moved:(NSArray<RiveSemanticsDiffNode*>*)moved
        childrenUpdated:(NSArray<RiveSemanticsChildrenUpdate*>*)childrenUpdated
        updatedSemantic:(NSArray<RiveSemanticsDiffNode*>*)updatedSemantic
        updatedGeometry:(NSArray<RiveSemanticsBoundsUpdate*>*)updatedGeometry
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveSemanticsDiff_h */
