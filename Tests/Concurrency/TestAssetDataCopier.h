#import "RiveAssetDataCopier.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AssetCopyFailure) {
    AssetCopyFailureBadAlloc,
    AssetCopyFailureLengthError,
};

@interface TestAssetDataCopier : NSObject <RiveAssetDataCopier>
- (instancetype)initWithFailure:(AssetCopyFailure)failure
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
