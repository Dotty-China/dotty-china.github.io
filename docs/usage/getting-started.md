---
layout: default
title: 用户入门
parent: 用法
nav_order: 1
---

# 试用 Scala 3

## 在浏览器中
[Scastie](https://scastie.scala-lang.org/?target=dotty) 是一个支持 Scala 3 的在线 Scala playground。这是一个快速尝试 Dotty 而无需安装额外程序的方式，它直接运行在您的浏览器中。

## sbt
最快的创建 Scala 3 新项目的方法是使用 [sbt(1.1.4+)](http://www.scala-sbt.org/)。

创建一个 Scala 3 项目：
```bash
$ sbt new scala/scala3.g8
```

或者创建一个与 Scala 2 交叉编译的 Scala 3 项目：
```bash
$ sbt new scala/scala3-cross.g8
```

你可以直接在 sbt 项目中启动 Scala 3 REPL：
```bash
$ sbt
> console
scala>
```

更多信息请参见 [Scala 3 Example Project](https://github.com/scala/scala3-example-project)。

## IDE 支持

在 Scala 3 项目中使用 IDE 的方式请参见 [IDE 指南](./ide-support.md)。

## 独立安装

可以在 Dotty 仓库的 [Releases 页面](https://github.com/lampepfl/dotty/releases)下载预构建的 Scala 3 发行版。
Scala 3 发行版包括三个可执行文件：Scala 3 编译器 `scalac`，[Scaladoc](scaladoc.md) 工具 `scaladoc`以及 Scala3 REPL `scala`。

```
.
└── bin
    ├── scalac
    ├── scaladoc
    └── scala
```

将这些文件添加至 `PATH` 环境变量中就能这样在终端里直接使用这些命令：

```bash
# 编译 Scala 3 代码
$ scalac HelloWorld.scala

# 在恰当的 classpath 中运行程序
$ scala HelloWorld

# 启动 Scala 3 REPL
$ scala
Starting dotty REPL...
scala>
```

如果您是 Mac 用户，我们提供了 [homebrew](https://brew.sh/) package，您可以这样安装：

```bash
brew install lampepfl/brew/dotty
```

如果您已经使用 homebrew 安装了 Scala 3，那也可以这样更新它：

```bash
brew upgrade dotty
```

## Scala 3 脚本

如果您已经按照“独立安装”一节的步骤安装了 Scala 3，并且确定 `scala` 工具在您的 `PATH` 环境变量中，那么您可以以脚本的形式执行 `*.scala` 文件。给定一个叫做 `Test.scala` 的源文件：

```scala
@main def Test(name: String): Unit =
  println(s"Hello ${name}!")
```

您可以执行 `scala Test.scala World` 并得到输出 `Hello World!`。

“脚本”是包含主方法的普通 Scala 文件。`scala Script.scala` 命令的语义如下：

- 使用 `scalac` 编译 `Script.scala` 文件，输出放到临时文件夹内。
- 在生产的 `*.class` 文件中检测主方法。
- 执行主方法。
