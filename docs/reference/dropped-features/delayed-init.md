---
layout: default
title: "已删除：延迟初始化"
parent: 已删除的特性
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

对 trait `DelayedInit` 的特殊处理不再被支持。

这造成的后果之一是使用 `DelayedInit` 的类 `App` 被部分破坏。
您现在依然可以使用 `App` 作为定义主程序的简便方法。例如：

```scala
object HelloWorld extends App {
   println("Hello, world!")
}
```

但是，这段代码现在是在对象的初始化器中执行，这在某些 JVM 上意味着它们会被解释执行。
所以，最好不要将它用于基准测试！另外，如果要访问命令行参数，则需要使用显式的 `main` 方法。

```scala
object Hello {
   def main(args: Array[String]) =
      println(s"Hello, ${args(0)}")
}
```

另一方面，Scala 3 提供了一个便捷的替代方案 [`@main` 方法](../changed-features/main-functions.md)
实现以上的“程序”对象。
