# zed-xmake-guide

�?**Windows + xmake + MSVC** 上用 **Zed / clangd** 愉快�?C/C++ 的配置模板与指南�?

核心解决一个让人抓狂的问题�?*xmake 编译好好的，Zed 里却报一堆假�?*�?

```
'hv/hloop.h' file not found
Call to undeclared library function 'printf' ... implicit function declaration
```

根因�?clangd �?`compile_commands.json`——于是拿不到依赖�?`-I` 路径，也没进�?MSVC 模式。本仓库给你**一套开箱即用的修复**：xmake 自动生成编译数据�?+ Zed 配置模板 + 完整文档�?

## 快速开�?

1. �?[`templates/clangd_export.lua`](./templates/clangd_export.lua) 拷进你的 xmake 项目
2. �?`xmake.lua` 加两行：

```lua
includes("clangd_export.lua")
-- ...
target("app")
    add_rules("clangd_export")
```

3. 重新 `xmake`（自动生�?`compile_commands.json`�?
4. Zed �?`Ctrl+Shift+P` �?`zed: reload workspace`

假错消失。就是这么简单—�?*不需�?clang-cl，不需要手�?`.clangd`，不需要改工具链�?*

## 目录

```
├── config/
�?  └── zed/
�?      └── settings.json        # Zed 配置模板（主�?+ clangd�?
├── docs/
�?  ├── xmake-clangd-windows.md  # 核心指南：问题根�?+ 修复 + FAQ
�?  └── windows-env-setup.md     # 从零搭环境：LLVM / VS / xmake / Zed
├── templates/
�?  ├── clangd_export.lua        # �?xmake 自动生成 compile_commands.json 规则
�?  └── xmake.lua                # 使用示例
└── README.md
```

## 为什么不�?clang-cl�?

clang-cl �?**Windows 上用 MSVC 风格参数调用 clang** 的驱动，用于"�?clang 前端编译但仍保持 MSVC 兼容"。它**不解决索引问题，也不是跨平台方案**。clangd 索引靠的�?`compile_commands.json`——只�?DB 里是 `cl.exe`，clangd 自动进入 MSVC 模式。想深究�?[docs/xmake-clangd-windows.md](./docs/xmake-clangd-windows.md) �?FAQ�?

## 已验�?

�?Windows + xmake + MSVC 2026 上实测：

- 全量构建 �?自动生成 DB�? entries，`cl.exe`�?
- **增量构建**（无源码变化）→ 仍刷�?DB，保持最�?
- clangd CLI 校验：`All checks completed, 0 errors`

## 许可�?

[MIT](./LICENSE)
