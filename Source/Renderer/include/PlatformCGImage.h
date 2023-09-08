/*
 * Copyright 2023 Rive
 */

#pragma once

#include <vector>

// Represents raw, premultiplied, RGBA image data with tightly packed rows (width * 4 bytes).
struct PlatformCGImage
{
    uint32_t width = 0;
    uint32_t height = 0;
    bool opaque = false;
    std::vector<uint8_t> pixels;
};

// Decodes the given bytes into 'platformImage'.
//
// Returns false and leaves 'platformImage' unchaged on failure.
[[nodiscard]] bool PlatformCGImageDecode(const uint8_t* encodedBytes,
                                         size_t encodedSizeInBytes,
                                         PlatformCGImage* platformImage);
