---
layout: default
title: "已删除：存在类型"
parent: 已删除的特性
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

使用 `forSome`（[SLS §3.2.12](https://www.scala-lang.org/files/archive/spec/2.13/03-types.html#existential-types)）
的存在类型（Existential Type）被删除。删除它们的原因是：

 - 存在类型违背了 DOT 和 Scala 3 的类型完备性原则。
   该原则要求类型选择 `p.T` 或 `S#T` 中的每个前缀（`p` 或 `S`），
   要么来自运行时构造的值，要么引用已知的只有良好边界的类型。
   
 - Existential types create many difficult feature interactions
   with other Scala constructs.

 - 存在类型很大程度上与路径依赖类型（path-dependent type）重叠，因此拥有它的好处相对较小。

现在依然支持只用通配符（而不使用 `forSome`） 表示的存在类型，
但会将其视为 refined type。

例如，类型

```scala
Map[_ <: AnyRef, Int]
```
被视为类型 `Map`，其中第一个类型参数是 upper-bounded by `AnyRef`，
第二个类型参数是 `Int` 的别名。

当读取使用 Scala 2 编译的 class 文件时，Scala 3 会尽最大努力使用自己的类型来模拟存在类型。
它会发出警告说明自己无法进行精确的模拟。
