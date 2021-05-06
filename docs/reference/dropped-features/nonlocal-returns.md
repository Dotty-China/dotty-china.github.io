---
layout: default
title: "已删除：非局部返回"
parent: 已删除的特性
grand_parent: 参考
nav_order: 15
---

# {{ page.title }}

从内部匿名函数中 return 已经被弃用。

非局部返回是通过抛出和捕捉 `scala.runtime.NonLocalReturnException` 实现的。这很少是程序员想要的。
抛出和捕获异常会带来额外的隐藏性能开销，可能会造成问题。
此外，这是一个有漏洞的实现：捕获所有异常的异常处理程序可以截获 `NonLocalReturnException`。

[`scala.util.control.NonLocalReturns`](http://dotty.epfl.ch/api/scala/util/control/NonLocalReturns$.html) 
中提供了一套 drop-in 的库替代品。例如：

```scala
import scala.util.control.NonLocalReturns.*

extension [T](xs: List[T]) {
   def has(elem: T): Boolean = returning {
      for x <- xs do
         if x == elem then throwReturn(true)
      false
   }
}

@main def test(): Unit = {
   val xs = List(1, 2, 3, 4, 5)
   assert(xs.has(2) == xs.contains(2))
}
```
