#import "TestAssetDataCopier.h"
#include <new>
#include <stdexcept>

@implementation TestAssetDataCopier
{
    AssetCopyFailure _failure;
}

- (instancetype)initWithFailure:(AssetCopyFailure)failure
{
    if (self = [super init])
    {
        _failure = failure;
    }
    return self;
}

- (std::vector<uint8_t>)copyData:(NSData*)data
{
    switch (_failure)
    {
        case AssetCopyFailureBadAlloc:
            throw std::bad_alloc();
        case AssetCopyFailureLengthError:
            throw std::length_error("Test asset copy failure");
    }
}

@end
