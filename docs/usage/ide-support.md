---
layout: default
title: Scala 3 的 IDE 支持
parent: 用法
nav_order: 3
---

# {{ page.title }}

基于 [Scala Metals](https://scalameta.org/metals/) 的 IDE（例如 Visual Studio Code 和 vim）
以及 [IntelliJ IDEA](https://www.jetbrains.com/idea/) 支持 Scala 3。


## 使用 Visual Studio Code

要在 Scala 3 项目上使用 Visual Studio Code，请确保已经安装了 [Metals](https://scalameta.org/metals/docs/editors/vscode.html) 插件。
然后再 VS Code 打开项目文件夹，并单击弹出的通知上的“Import build”按钮。


### 幕后工作

VS Code 使用 [Language Server Protocol (LSP)](https://github.com/Microsoft/language-server-protocol) 实现语义化特性（例如补全和 “go to definition”），
因此需要一个 Scala 的 LSP 实现。Metals 是 Scala 的 LSP 实现。它从 Scala 3 编译器直接生成的 [semanticdb](https://scalameta.org/docs/semanticdb/guide.html)
中提取语义信息。

您可以从[这篇博文]((https://medium.com/virtuslab/introduction-to-metals-with-scala-3-79ebf3120a95))中了解更多关于 Metals 对 Scala 3 支持的内容。

为了与构建工具通信（例如导入项目、触发构建以及运行测试），Metals 使用 [Build Server Protocol (BSP)](https://build-server-protocol.github.io/)。
Metals 使用的默认 BSP 实现是 [Bloop](https://scalacenter.github.io/bloop/)，它支持 Scala 3 项目。
另外，[sbt 也可以作为 BSP 服务器使用](https://scalameta.org/metals/blog/2020/11/06/sbt-BSP-support.html)，从 1.4 开始 sbt 直接实现了 BSP。

## 使用 IntelliJ IDEA

IntelliJ 有自己的语义化特性实现，因此它不适用 Metals 或者 [Language Server Protocol (LSP)](https://github.com/Microsoft/language-server-protocol)。

要将项目导入 IntelliJ 有两种方式：

- 使用内置的导入 sbt 构建功能
= 使用 IntelliJ 对 [Build Server Protocol (BSP)](https://www.jetbrains.com/help/idea/bsp-support.html) 的支持


### 导入 sbt 构建

要使用 IntelliJ 的 sbt 导入功能，请转到 “File” - “Open...”，然后选择您项目的 `build.sbt` 文件。

在这个模式下，IntelliJ 会用一个自定义插件启动 sbt 提取项目解构。导入后，IntelliJ 不再与其他 sbt 会话交互。
IDE 中构建和运行项目是由独立进程完成的。

### 使用 BSP 导入项目

要使用 BSP 导入项目，请转到 “File” - “Open...” - “Project from Existing Sources”，然后选择您的项目文件夹。在接下来的对话框中，选择 “BSP” 导入项目。
您可能需要在 “sbt” 和 “sbt with Bloop” 选项之间进行选择，建议选择 “sbt” 选项。

如果项目导入失败（“Problem executing BSP job”），请在终端内进入您的项目，然后启动 `sbt`。当 sbt 运行时，打开 IntelliJ 的 “bsp” 标签页然后点击 
“Reload” 按钮。

当使用 IntelliJ 的 BSP 模式时，IDE 中的构建和执行命令通过 sbt 执行，因此它们与终端中通过 sbt 构建运行项目有着相同的效果。
