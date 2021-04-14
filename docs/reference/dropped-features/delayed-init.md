---
layout: default
title: "已弃用：延迟初始化"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 1
---

The special handling of the `DelayedInit` trait is no longer supported.

One consequence is that the `App` class, which used `DelayedInit` is
now partially broken. You can still use `App` as a simple way to set up a main program. Example:

```scala
object HelloWorld extends App {
   println("Hello, world!")
}
```

However, the code is now run in the initializer of the object, which on
some JVM's means that it will only be interpreted. So, better not use it
for benchmarking! Also, if you want to access the command line arguments,
you need to use an explicit `main` method for that.

```scala
object Hello:
   def main(args: Array[String]) =
      println(s"Hello, ${args(0)}")
```

On the other hand, Scala 3 offers a convenient alternative to such "program" objects
with [`@main` methods](../changed-features/main-functions.md).
