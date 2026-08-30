-- Sample xmake.lua using the clangd_export rule
-- 1) copy templates/clangd_export.lua into your project
-- 2) include it and attach the rule to each target
add_rules("mode.debug", "mode.release")
includes("clangd_export.lua")

-- add_requires("libhv", {configs = {protocol = true}})

target("app")
    set_kind("binary")
    add_rules("clangd_export")   -- <-- auto-generates compile_commands.json on build
    add_files("src/main.c")
    -- add_packages("libhv")
