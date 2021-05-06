---
layout: default
title: "已删除：22 限制"
parent: 已删除的特性
grand_parent: 参考
nav_order: 10
---

# {{ page.title }}

函数参数与元组字段的最多为 22 个的限制被取消。

* 函数现在可以有任意个数的参数。超出 [`scala.Function22`](https://www.scala-lang.org/api/current/scala/Function22.html)
  的函数会被擦除为另一个新的 trait [`scala.runtime.FunctionXXL`](https://dotty.epfl.ch/api/scala/runtime/FunctionXXL.html)。

* 元组现在也可以有任意个数的字段。超出 [`scala.Tuple22`](https://www.scala-lang.org/api/current/scala/Tuple22.html)
  的元组会被擦除到另一个新类 [`scala.runtime.TupleXXL`](https://dotty.epfl.ch/api/scala/runtime/TupleXXL.html)
  （它继承了 trait [`scala.Product`](https://dotty.epfl.ch/api/scala/Product.html)）。
  此外，元组现在还支持类似连接和索引的通用操作。

这两者都是通过数组实现的。
