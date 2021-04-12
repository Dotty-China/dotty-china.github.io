---
layout: default
title: Scala 3 IDE 中的 Worksheet 模式
parent: 用法
nav_order: 4
---

Worksheet 是在保存时被执行的 Scala 文件，每个表达式的结果显示在程序右侧的一列中。Worksheet 就像一个 steroids 上的 REPL 会话，
并享受一等的编辑器支持：补全、超链接、键入时的交互式报错等。Worksheet 使用 `.sc` 扩展名。



## 如何使用 Worksheet

目前唯一支持 Worksheet 模式的终端是 [Visual Studio Code](https://code.visualstudio.com/)。

要使用 Worksheet，请按照[说明](ide-support.md)启动 Scala 3 IDE 创建一个新文件 `MyWorksheet.sc`，并写下以下代码：

```scala
val xyz = 123
println("Hello, worksheets!")
456 + xyz
```

缓存区顶部会显示消息 `Run this worksheet`。点击它执行 Worksheet 代码。输出的每一行都打印在生成它的表达式右侧。
Worksheet 与项目的类和类路径上的依赖项一起执行。

![Run worksheet](https://z3.ax1x.com/2021/04/12/cDNxjs.png)

默认情况下，保存 Worksheet 文件时也会执行 Worksheet。可以在 VSCode preferences 中配置这个行为：

![Configure run on save](https://z3.ax1x.com/2021/04/12/cDUSun.png)

请注意，Worksheet 与 Scala 3 IDE 的其余部分完全集成：输入时会提示错误、建议补全，并且你可以使用 Scala 3 IDE 的所有其他功能，
例如 go to definition、find all references 等。

![IDE features in the worksheet](https://z3.ax1x.com/2021/04/12/cDNvcj.png)

## 实现细节

Worksheet 模式的实现细节以及为其他客户端添加支持的信息可以在 [Worksheet 模式 - 实现细节](worksheet-mode-implementation-details.md)中找到。
