/*
 * Copyright 2023 Rive
 */

#pragma once

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#elif TARGET_OS_MAC
#include <ApplicationServices/ApplicationServices.h>
#endif

// Helper that remembers to call CFRelease when an object goes out of scope.
template <typename T> class AutoCF
{
public:
    AutoCF() = default;
    AutoCF(T obj) : m_Obj(obj) {}
    AutoCF(const AutoCF&) = delete;
    AutoCF& operator=(const AutoCF&) = delete;
    ~AutoCF() { adopt(nullptr); }

    void adopt(T obj)
    {
        if (m_Obj)
            CFRelease(m_Obj);
        m_Obj = obj;
    }

    operator T() const { return m_Obj; }
    operator bool() const { return m_Obj != nullptr; }
    T get() const { return m_Obj; }

private:
    T m_Obj = nullptr;
};
