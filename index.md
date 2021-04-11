---
layout: default
title: 主页
nav_order: 1
description: "Just the Docs is a responsive Jekyll theme with built-in search that is easily customizable and hosted on GitHub Pages."
permalink: /
---
**Dotty 中文站正在更新中。**

## 试用 Scala 3

有几种方法可以开始使用 Scala 3。

1. 您可以在浏览器中用 [Scastie](https://scastie.scala-lang.org/?target=dotty) 试用 Scala 3。
2. 如果您已经安装了 sbt，那么就可以[创建一个 Scala 3 项目](#%E5%88%9B%E5%BB%BA%E4%B8%80%E4%B8%AA-scala-3-%E9%A1%B9%E7%9B%AE)，sbt 会处理其他工作。
3. 您可以运行 `cs setup` 使用 [coursier](https://get-coursier.io/) 安装必要的依赖。你可以运行 `cs install scala3-compiler` 和 `cs install scala3-repl` 来安装 Scala 3 的编译器和 REPL 命令行工具。
4. 您可以在您的电脑上[手动安装](#%E5%AE%89%E8%A3%85-scala-3) Scala 3。

## 安装 Scala 3

如果您是 **Mac** 用户，那么您可以用 [brew](https://brew.sh/) 安装 Scala 3：

```
brew install lampepfl/brew/dotty
```

如果您是 **Linux** 或 **Windows** 用户，那么需要在系统上安装 JDK 8 或者更高的版本，环境变量 `JAVA_HOME` 应该指向 JDK 安装的位置。

对于 **Windows** 用户，我们建议使用 [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) 或者其他 bash shell 环境，例如 [git bash](https://gitforwindows.org/)。

然后下载[最新版本](https://github.com/lampepfl/dotty/releases)文件。（可选的）将 `bin/` 文件夹的路径加入系统 `PATH` 环境变量中。

现在您可以这样编译 Scala 代码：

```
scalac hello.scala
```

运行 `scala` 可以启动 REPL。

## 创建一个 Scala 3 项目

最快的创建 Scala 3 新项目的方法是使用 sbt(1.1.4+)。

创建一个 Scala 3项目：

```
sbt new lampepfl/dotty.g8
```

或者创建一个与 Scala 2 交叉编译的 Scala 3 项目：

```
sbt new lampepfl/dotty-cross.g8
```

相关文档参见 [Scala 3 Example Project](https://github.com/scala/scala3-example-project)。

## 更多关于 Scala 3 的信息

你可以从这些地方找到更多有关 Scala 3 的信息：

* [Scala 3 文档](https://docs.scala-lang.org/scala3/)
* [Scala 3 book](https://docs.scala-lang.org/scala3/book/introduction.html)
* [Scala 3 参考文档](https://dotty.epfl.ch/docs/index.html)
* [Scala 3 教程](https://docs.scala-lang.org/scala3/guides.html)