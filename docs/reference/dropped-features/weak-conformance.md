---
layout: default
title: "已删除：弱一致性"
parent: 已删除的特性
grand_parent: 参考
nav_order: 14
---

# {{ page.title }}

某些情况下，Scala 在测试类型兼容性或计算一组类型的最小上界时
使用*弱一致性（weak conformance）*关系。弱一致性背后的主要动机
是让这样的表达式具有 `List[Double]` 类型：

```scala
List(1.0, math.sqrt(3.0), 0, -3.3) // : List[Double]
```

很“显然”，这应该是 `List[Double]`。但是，如果没有一些特殊规定，列表的元素类型 
`(Double, Double, Int, Double)` 的最小上界将是 `AnyVal`，因此列表会被赋予类型 
`List[AnyVal]`。

下面是一个不太显然的例子，它也会使用弱一致性关系得到类型 `List[Double]`。

```scala
val n: Int = 3
val c: Char = 'X'
val d: Double = math.sqrt(3.0)
List(n, c, d) // used to be: List[Double], now: List[AnyVal]
```

在这里，类型怎么扩大到 `List[Double]` 的不太清晰，
`List[AnyVal]` 似乎是同样有效的 —— 并且更 principled —— 的选择。

弱一致性适用于所有“数字”类型（包括 `Char`），并与表达式是否为字面量无关。
然而事后来看，这唯一的预期用途就是使*整数字面量*适应其他表达式的类型。
其他数字的类型在其语法中嵌入了显式的类型注释（`f`、`d`、`.`、`L`，以及 `Char` 的 `'`），
这确保了它们的作者真正想要它们具有特定的类型。

因此，Scala 3 放弃了弱一致性的一般概念，只保留了一条规则：
`Int` 字面量在必要时可以适应其他数字类型。

[更多细节]](weak-conformance-spec.md){: .btn .btn-purple }
