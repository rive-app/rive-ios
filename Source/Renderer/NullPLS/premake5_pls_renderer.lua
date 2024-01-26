dofile('rive_build_config.lua')

newoption({ trigger = 'no-rive-decoders', description = '' })

-- Build a no-op librive_pls_renderer.a so xcode still sees a static library to link with when the
-- module isn't available.
project('rive_pls_renderer')
do
    kind('StaticLib')
    files({ 'pls.cpp' })
end

newoption({
    trigger = 'variant',
    value = 'type',
    description = 'Choose a particular variant to build',
    allowed = {
        { 'system', 'Builds the static library for the provided system' },
        { 'emulator', 'Builds for an emulator/simulator for the provided system' },
    },
    default = 'system',
})
