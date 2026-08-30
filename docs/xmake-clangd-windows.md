# Xmake + Windows + clangd: 让 Zed 不再报假错

本指南解决一个在 **Windows + xmake + MSVC** 下非常常见、但文档很少讲清的问题：
Zed / clangd 在编辑 C/C++ 时疯狂报错，例如：

```
'hv/hloop.h' file not found
Call to undeclared library function 'printf' ... ISO C99 and later do not support implicit function declarations
```

实际上 `xmake build` 编译**完全正常**、能出 exe。错只出现在编辑器里。

## 为什么会这样

clangd 需要一份 **compile_commands.json**（编译数据库）才知道：

1. 每个源文件的 `-I` 头文件搜索路径（比如 libhv 的 `include` 目录）
2. 编译宏（如 `-DHV_STATICLIB`）
3. 用的是 MSVC 工具链（从而自动找到 `<stdio.h>` 等 MSVC/Windows SDK 头文件）

**如果没有 compile_commands.json**，clangd 会退回一条"裸命令"`clang -- src.c`：

- 没有 `-I libhv` → `hv/hloop.h file not found`
- 没进入 MSVC 模式 → 找不到 `<stdio.h>`，`printf` 就报 *implicit function declaration*

## 修复（三步）

### 第 1 步：让 xmake 自动生成 compile_commands.json

把 `templates/clangd_export.lua` 拷进你的项目，然后在 `xmake.lua` 顶部加一行 include，并给每个 target 加 `add_rules("clangd_export")`：

```lua
add_rules("mode.debug", "mode.release")
includes("clangd_export.lua")          -- <-- 引入规则

target("app")
    set_kind("binary")
    add_rules("clangd_export")          -- <-- 每个 target 加这行
    add_files("src/main.c")
    add_packages("libhv")               -- 你的依赖照常
```

之后每次 `xmake`（**包括增量构建**）都会在项目根目录自动生成 / 刷新 `compile_commands.json`。

> 为什么用 `before_build` 而不是 `after_build`？
> 源文件的编译批次（source batches）在构建**过程中会被消费掉**，`after_build` 时它们已经不在了，生成出来的 DB 会是 **空的**（0 entries）。所以必须用 `before_build`，在真正编译前、批次还完整时生成。

### 第 2 步：无需 clang-cl / 无需改工具链

关键结论：**你不需要把构建切到 clang-cl，也不需要 `.clangd` 手工写一堆 `-isystem`。**

- 只要 DB 里是 `cl.exe`，clangd **会自动进入 MSVC 模式**并找到 MSVC + Windows SDK 头文件。
- DB 里已经带上了 libhv 等的 `-I` 路径，clangd 直接就能解析。

> 反而要注意：**不要**再用 `.clangd` 的 `CompileFlags.Add` 重复加 include 路径——clangd 22 存在一个 bug，重复的 `-isystem` 会和 DB 里的 `/Fo` 输出参数冲突，从而报新的 driver 错误。**只依赖 DB 即可。**

### 第 3 步：在 Zed 里 reload 项目

```
Ctrl+Shift+P → "zed: reload workspace"   （或重开项目窗口）
```

clangd 会重新加载 compile_commands.json，假错消失。

## 验证方法（不依赖编辑器）

用 clangd CLI 直接检查，确认真的修好了：

```bash
clangd --check=src/server.c --compile-commands-dir=.
# 期望输出： All checks completed, 0 errors
```

在项目根目录跑，如果看到 `0 errors`，说明索引正确，Zed 里 reload 后同样会好。

## 常见问题

### Q: 什么时候才需要 clang-cl？
A: clang-cl 是 **Windows 上用 MSVC 风格参数调用 clang** 的驱动，只在前端编译、又要保持 MSVC 兼容（`/MD`、ABI、和 VC++ 混链）时才用。**它不解决索引问题**，也不是跨平台方案。想用 clang 前端编译：

```bash
xmake f --toolchain=clang-cl
```

但那样会要求所有依赖（如 libhv）都用 clang 重新编译，代价大、通常没必要。默认 MSVC 即可，clangd 照常索引。

### Q: 为什么我有时 `printf` 也报错但编译却好？
A: 就是没进 MSVC 模式 / 没找到 `<stdio.h>`——是索引问题，不是代码问题。按上文生成 DB 即可。

### Q: clangd 找不到 SDD / 标准库？
A: 只要 DB 由 MSVC 工具链生成（cl.exe），clangd 会自动探测 `vswhere` + Windows SDK。若你的 VS 装在非常规位置（如 `D:\VS`）导致自动探测失败，在 Zed 的 clangd `arguments` 里加：

```json
"--query-driver=C:\\<your-VS>\\VC\\Tools\\MSVC\\*\\bin\\Hostx64\\x64\\cl.exe"
```

## 平台覆盖

这套方案同时覆盖 **Windows / Linux / macOS**：clangd 读 DB 是跨平台的，只是 Windows 上多了 MSVC 自动探测这一层。用 gcc / clang / mingw 工具链时同理，只要 DB 生成正确即可。
