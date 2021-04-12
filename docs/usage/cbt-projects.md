---
layout: default
title: Scala 3 与 CBT
parent: 用法
nav_order: 6
---

# {{ page.title }}

**注意：CBT 对 Scala 3 的支持是实验性的、不完整的（例如不支持增量编译），我们建议现在[使用 SBT](sbt-projects.md)。**

CBT 带有内置的 Scala 3 支持。按照 [CBT 教程](https://github.com/cvogt/cbt/)，简单地用 Build 类继承 `Dotty`。

```scala
// build/build.scala
import cbt.*
class Build(val context: Context) extends Dotty {
  ...
}
```

详情参见 [example project](https://github.com/cvogt/cbt/tree/master/examples/dotty-example)。
