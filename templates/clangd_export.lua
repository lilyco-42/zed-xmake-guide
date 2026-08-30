-- clangd_export.lua
-- ---------------------------------------------------------------------------
-- Reusable xmake rule: auto-generate compile_commands.json before each build so
-- clangd / clang-based tools can index your C/C++ project correctly.
--
-- Why: without a compile_commands.json, clangd falls back to a bare `clang`
-- invocation and on Windows/MSVC it cannot resolve your package include dirs
-- (e.g. hv/hloop.h "file not found") nor even <stdio.h>. Generating the file
-- after/before build lets clangd auto-detect MSVC and read all -I paths.
--
-- This handles the Windows + MSVC case out of the box AND is cross-platform
-- (works with gcc/clang/minigw toolchains too).
--
-- Cross-platform note: for the Windows/MSVC build we keep the default MSVC
-- toolchain (compile_commands.json then carries cl.exe -> clangd auto-detects
-- MSVC). You do NOT need clang-cl for indexing. If you prefer to actually
-- build with the clang frontend while staying MSVC-compatible, use:
--     xmake f --toolchain=clang-cl
-- ---------------------------------------------------------------------------

rule("clangd_export")
    -- Run once per process, before the (first) target compiles, when the
    -- source batches are still intact so the database is fully populated.
    -- before_build (not after_build) is important: source batches are consumed
    -- during the build, so after_build would produce an empty database.
    before_build(function (target)
        -- only generate once no matter how many targets there are
        if _g.clangd_export_done then
            return
        end
        _g.clangd_export_done = true

        -- avoid recursion when this itself runs inside a project generator
        if os.getenv("XMAKE_IN_PROJECT_GENERATOR")
           or os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            return
        end

        import("core.project.config")
        import("core.base.task")
        import("plugins.project.clang.compile_commands", {rootdir = os.programdir()})
        task.run("config", {}, {loadonly = true})
        compile_commands.make(os.projectdir())
        cprint("${bright cyan}[clangd_export] compile_commands.json generated")
    end)
