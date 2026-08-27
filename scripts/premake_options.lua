-- premake5_pls_renderer.lua leaves this option and the RIVE_CANVAS define to
-- the including project; supply both for the standalone pls builds.
newoption({
    trigger = 'with_rive_canvas',
    description = 'Compiles in RenderCanvas and Ore GPU abstraction layer.',
})
if _OPTIONS['with_rive_canvas'] then
    defines({ 'RIVE_CANVAS' })
    -- The core runtime invocation never loads the pls renderer script, so its
    -- lua gpu sources need the Apple ore backend defines from here.
    if os.target() == 'ios' or os.target() == 'macosx' then
        defines({ 'RIVE_ORE', 'ORE_BACKEND_METAL' })
    end
end
