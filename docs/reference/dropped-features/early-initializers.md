---
layout: default
title: "已删除：Early 初始化"
parent: 已删除的特性
grand_parent: 参考
nav_order: 8
---

# {{ page.title }}

这种形式的 Early 初始化器

```scala
class C extends { ... } with SuperClass ...
```

已经被删除。它们很少被使用，主要用来弥补没有 [trait 参数](../other-new-features/trait-parameters.md)的问题，
而现在 Scala 3 直接支持这个功能。

更多信息请参见 [SLS §5.1.6](https://www.scala-lang.org/files/archive/spec/2.13/05-classes-and-objects.html#early-definitions)。
