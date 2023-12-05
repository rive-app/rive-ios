workspace 'rive'
configurations {'debug', 'release'}

require 'setup_compiler'

newoption {
    trigger = 'no-rive-decoders',
    description = ''
}

newoption {
    trigger = 'universal-release',
    description = ''
}

-- Build a no-op librive_pls_renderer.a so xcode still sees a static library to link with when the
-- module isn't available.
project 'rive_pls_renderer'
do
    kind 'StaticLib'
    language 'C++'
    cppdialect 'C++17'
    targetdir '%{cfg.buildcfg}'
    objdir 'obj/%{cfg.buildcfg}'
    files {'../pls.cpp'}

    if os.host() == 'macosx' then
        iphoneos_sysroot = os.outputof('xcrun --sdk iphoneos --show-sdk-path')
        iphonesimulator_sysroot = os.outputof('xcrun --sdk iphonesimulator --show-sdk-path')

        filter {'system:macosx'}
        do
            buildoptions {
                '-arch x86_64',
                '-arch arm64',
            }
        end

        filter {'system:ios', 'options:variant=system'}
        do
            targetdir 'iphoneos_%{cfg.buildcfg}'
            objdir 'obj/iphoneos_%{cfg.buildcfg}'
            buildoptions {
                '--target=arm64-apple-ios13.0.0',
                '-mios-version-min=13.0.0',
                '-arch arm64',
                '-isysroot ' .. iphoneos_sysroot
            }
        end

        filter {'system:ios', 'options:variant=emulator'}
        do
            targetdir 'iphonesimulator_%{cfg.buildcfg}'
            objdir 'obj/iphonesimulator_%{cfg.buildcfg}'
            buildoptions {
                '--target=arm64-apple-ios13.0.0-simulator',
                '-mios-version-min=13.0.0',
                '-arch x86_64',
                '-arch arm64',
                '-isysroot ' .. iphonesimulator_sysroot
            }
        end
    end
end

newoption {
    trigger = 'variant',
    value = 'type',
    description = 'Choose a particular variant to build',
    allowed = {
        {'system', 'Builds the static library for the provided system'},
        {'emulator', 'Builds for an emulator/simulator for the provided system'}
    },
    default = 'system'
}
