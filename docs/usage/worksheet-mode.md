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

To use the worksheets, start Dotty IDE by [following the
instruction](ide-support.md) and create a new file `MyWorksheet.sc` and
write some code:

```scala
val xyz = 123
println("Hello, worksheets!")
456 + xyz
```

On top of the buffer, the message `Run this worksheet` appears. Click it to
evaluate the code of the worksheet. Each line of output is printed on the right
of the expression that produced it. The worksheets run with the classes of your
project and its dependencies on their classpath.

![](../../images/worksheets/worksheet-run.png "Run worksheet")

By default, the worksheets are also run when the file is saved. This can be
configured in VSCode preferences:

![](../../images/worksheets/config-autorun.png "Configure run on save")

Note that the worksheet are fully integrated with the rest of Dotty IDE: While
typing, errors are shown, completions are suggested, and you can use all the
other features of Dotty IDE such as go to definition, find all references, etc.

![](../../images/worksheets/worksheet-help.png "IDE features in the worksheet")

Implementation details
======================

The implementation details of the worksheet mode and the information necessary to add support for
other clients are available in [Worksheet mode - Implementation
details](worksheet-mode-implementation-details.md).
