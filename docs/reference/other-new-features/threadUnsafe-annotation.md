---
layout: default
title: "@threadUnsafe 注解"
parent: 其他新特性
grand_parent: 参考
nav_order: 10
---

# `@threadUnsafe` 注解

新的注解 `@threadUnsafe` 可以用在 `lazy val` 属性上。使用此注解时，
`lazy val` 会使用更快，但不是线程安全的机制进行初始化。

## 示例

```scala
import scala.annotation.threadUnsafe

class Hello {
   @threadUnsafe lazy val x: Int = 1
}
```
