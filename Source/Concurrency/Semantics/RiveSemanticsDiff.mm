//
//  RiveSemanticsDiff.mm
//  RiveRuntime
//

#import "RiveSemanticsDiff.h"

@implementation RiveSemanticsDiffNode

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
              siblingIndex:(uint32_t)siblingIndex
{
    self = [super init];
    if (self)
    {
        _nodeID = nodeID;
        _role = role;
        _label = [label copy];
        _value = [value copy];
        _hint = [hint copy];
        _stateFlags = stateFlags;
        _traitFlags = traitFlags;
        _headingLevel = headingLevel;
        _minX = minX;
        _minY = minY;
        _maxX = maxX;
        _maxY = maxY;
        _parentID = parentID;
        _siblingIndex = siblingIndex;
    }
    return self;
}

@end

@implementation RiveSemanticsBoundsUpdate

- (instancetype)initWithID:(uint32_t)nodeID
                      minX:(float)minX
                      minY:(float)minY
                      maxX:(float)maxX
                      maxY:(float)maxY
{
    self = [super init];
    if (self)
    {
        _nodeID = nodeID;
        _minX = minX;
        _minY = minY;
        _maxX = maxX;
        _maxY = maxY;
    }
    return self;
}

@end

@implementation RiveSemanticsChildrenUpdate

- (instancetype)initWithParentID:(int32_t)parentID
                        childIDs:(NSArray<NSNumber*>*)childIDs
{
    self = [super init];
    if (self)
    {
        _parentID = parentID;
        _childIDs = [childIDs copy];
    }
    return self;
}

@end

@implementation RiveSemanticsDiff

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
{
    self = [super init];
    if (self)
    {
        _frameNumber = frameNumber;
        _treeVersion = treeVersion;
        _rootID = rootID;
        _removed = [removed copy];
        _added = [added copy];
        _moved = [moved copy];
        _childrenUpdated = [childrenUpdated copy];
        _updatedSemantic = [updatedSemantic copy];
        _updatedGeometry = [updatedGeometry copy];
    }
    return self;
}

@end
