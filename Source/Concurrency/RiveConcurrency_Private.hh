//
//  RiveConcurrency_Private.hh
//  RiveRuntime
//
//  Created by David Skuza on 1/6/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef RiveConcurrency_Private_h
#define RiveConcurrency_Private_h

#include "rive/command_server.hpp"
#include "rive/command_queue.hpp"

@interface RiveCommandQueue ()
@property(nonatomic, readonly) rive::rcp<rive::CommandQueue> commandQueue;
@end

#endif /* RiveConcurrency_Private_h */
