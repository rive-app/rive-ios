//
//  RiveFallbackFontCache.m
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#import "RiveFallbackFontCache.h"
#import "RiveFont.h"

@implementation RiveFallbackFontCacheKey
@synthesize style = _style;
@synthesize character = _character;
@synthesize index = _index;

- (instancetype)initWithStyle:(RiveFontStyle*)style
                    character:(rive::Unichar)character
                        index:(uint32_t)index
{
    if (self = [super init])
    {
        _style = style;
        _character = character;
        _index = index;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object == nil)
    {
        return NO;
    }

    if (![object isKindOfClass:[RiveFallbackFontCacheKey class]])
    {
        return NO;
    }

    if (self == object)
    {
        return YES;
    }

    RiveFallbackFontCacheKey* other = (RiveFallbackFontCacheKey*)object;
    return [self.style isEqual:other.style] &&
           self.character == other.character && self.index == other.index;
}

- (NSUInteger)hash
{
    // This is a super basic hash function that may be able to be improved.
    // However, I don't imagine many collisions will happen based on the
    // simplicity of our current use case. - David
    return [self.style hash] ^ self.character ^ self.index;
}

- (id)copyWithZone:(NSZone*)zone
{
    return [[RiveFallbackFontCacheKey alloc] initWithStyle:[self.style copy]
                                                 character:self.character
                                                     index:self.index];
}

@end

@implementation RiveFallbackFontCacheValue
@synthesize font = _font;
@synthesize usesSystemShaper = _usesSystemShaper;

- (instancetype)initWithFont:(id)font usesSystemShaper:(BOOL)usesSystemShaper;
{
    if (self = [super init])
    {
        _font = font;
        _usesSystemShaper = usesSystemShaper;
    }
    return self;
}

@end
