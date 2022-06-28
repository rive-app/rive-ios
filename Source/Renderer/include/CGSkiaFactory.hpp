//
//  CGSkiaFactory.hpp
//  RiveRuntime
//
//  Created by Zachary Duncan on 6/28/22.
//  Copyright © 2022 Rive. All rights reserved.
//
// This file was copied from the runtime viewer project. It should be replaced

#ifndef CGSkiaFactory_hpp
#define CGSkiaFactory_hpp

#include "skia_factory.hpp"

namespace rive {

struct CGSkiaFactory : public SkiaFactory {
    std::vector<uint8_t> platformDecode(rive::Span<const uint8_t> span, ImageInfo* info) override;
};

} // namespace

#endif /* CGSkiaFactory_hpp */
