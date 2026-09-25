#import <Foundation/Foundation.h>
#import "RiveCommandQueue.h"

#ifdef __cplusplus
#include <vector>
#endif

NS_ASSUME_NONNULL_BEGIN

/// Copies asset data into a buffer owned by the command queue.
@protocol RiveAssetDataCopier <NSObject>
#ifdef __cplusplus
- (std::vector<uint8_t>)copyData:(NSData*)data;
#endif
@end

@interface RiveCommandQueueAssetDataCopier : NSObject <RiveAssetDataCopier>
@end

@interface RiveCommandQueue (AssetDataCopying)
- (instancetype)initWithAssetDataCopier:(id<RiveAssetDataCopier>)copier;
@end

NS_ASSUME_NONNULL_END
