---
layout: default
title: "@threadUnsafe 注解"
parent: 其他新特性
grand_parent: 参考
nav_order: 10
---

A new annotation `@threadUnsafe` can be used on a field which defines
a `lazy val`. When this annotation is used, the initialization of the
`lazy val` will use a faster mechanism which is not thread-safe.

### Example

```scala
import scala.annotation.threadUnsafe

class Hello:
   @threadUnsafe lazy val x: Int = 1
```
