---
layout: default
title: "已删除：通配符初始化器"
parent: 已删除的特性
grand_parent: 参考
nav_order: 17
---

# {{ page.title }}

语法

```scala
  var x: A = _
```

用于指示一个字段未初始化，现在这个语法已经被删除。
要得到一个未初始化的字段，现在需要写作

```scala
import scala.compiletime.uninitialized

var x: A = uninitialized
```

为了支持交叉编译，`_` 依然被支持，但它将在未来的 3.x 版本中被删除。
