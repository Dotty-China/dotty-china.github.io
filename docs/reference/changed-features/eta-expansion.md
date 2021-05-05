---
layout: default
title: 自动 Eta 扩展
parent: 其他变化的特性
grand_parent: 参考
nav_order: 15
---

# {{ page.title }}

从*方法（Method）*到*函数（Function）*的转换得到了改进，对于有一个或多个参数的方法会自动进行。

```scala
def m(x: Boolean, y: String)(z: Int): List[Int]
val f1 = m
val f2 = m(true, "abc")
```

这将创建两个函数值：

```scala
f1: (Boolean, String) => Int => List[Int]
f2: Int => List[Int]
```

语法 `m _` 不再需要，并会在未来被弃用。

## 自动 eta 扩展与零元方法

自动 eta 扩展不适用于使用空参数列表的“零元”方法。

```scala
def next(): T
```

对 `next` 的简单引用不会自动转换为函数。必须显式使用 `() => next()` 实现这一点。
又因为 `_` 语法将会被弃用，所以建议使用上述写法，而不是 `next _`。

自动 eta 扩展不适用于零元方法的原因是因为 Scala 会隐式插入 `()` 作为参数，
这将和 eta 扩展冲突。虽然 Scala 3 中对自动加入 `()` 添加了[限制](../dropped-features/auto-apply.md)，
但根本的模糊性依然存在。

[更多细节](eta-expansion-spec.md){: .btn .btn-purple }
