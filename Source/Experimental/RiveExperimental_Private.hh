//
//  RiveExperimental_Private.hh
//  RiveRuntime
//
//  Created by David Skuza on 1/6/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef RiveExperimental_Private_h
#define RiveExperimental_Private_h

#include "rive/command_server.hpp"
#include "rive/command_queue.hpp"
#include "rive/factory.hpp"

@interface RiveCommandQueue ()
@property(nonatomic, readonly) rive::rcp<rive::CommandQueue> commandQueue;
@end

@interface RiveRenderContext ()
- (rive::Factory*)factory;
@end

#endif /* RiveExperimental_Private_h */
