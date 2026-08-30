# Windows 开发环境搭建（Zed + xmake + MSVC + LLVM）

一步步搭一套可用的 Windows C/C++ 开发环境。假设你从零开始。

## 1. 安装 LLVM（clang / clangd / clang-cl / clang-format）

推荐用 [scoop](https://scoop.sh)（也支持 winget）：

```powershell
scoop install llvm
```

或 winget：

```powershell
winget install -e --id LLVM.LLVM
```

装完验证：

```powershell
clang --version
clangd --version
clang-format --version
```

## 2. 安装 Visual Studio（MSVC 工具链）

需要 **C++ 桌面开发** 工作负载（含 MSVC x64/x86 编译器、Windows SDK）。xmake 会用它来编译，clangd 会用它来探测头文件。

```powershell
# 用安装器勾选 "Desktop development with C++" 即可
```

## 3. 安装 xmake

```powershell
scoop install xmake
# 或
# powershell -c "irm https://xmake.io/psget.ps1 | iex"
```

## 4. 安装 Zed

从 https://zed.dev 下载 Windows 版。首次打开会自带 clangd 支持（通过 language servers）。

## 5. 跑通一个最小项目

```powershell
xmake create -l c hello
cd hello
xmake          # 用 MSVC 编译
xmake run      # 运行
```

## 6. 接入 clangd 索引（关键）

参考 [docs/xmake-clangd-windows.md](./xmake-clangd-windows.md)：

1. 把 `templates/clangd_export.lua` 拷进项目
2. `xmake.lua` 里 `includes("clangd_export.lua")` + target 加 `add_rules("clangd_export")`
3. `xmake` 生成 compile_commands.json
4. Zed 里 reload workspace

## 7. Zed 配置

复制 `config/zed/settings.json` 里的相关块到你的 Zed settings（见该文件顶部注释）。

## 常见坑速查

| 症状 | 原因 | 解决 |
|------|------|------|
| `hv/hloop.h file not found` | 没 DB，clangd 拿不到 `-I` | 生成 compile_commands.json |
| `printf` implicit declaration | clangd 没进 MSVC 模式，找不到 `<stdio.h>` | 生成 DB（cl.exe → 自动探测） |
| 构建要重编所有依赖 | 切了 clang-cl 工具链 | 默认保留 MSVC |
| clangd 找不到 SDK | VS 装在非常规路径 | clangd arguments 加 `--query-driver=cl.exe` |
