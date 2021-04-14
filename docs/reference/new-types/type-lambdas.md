---
layout: default
title: 类型 Lambda
parent: 新类型
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

*类型 Lambda*能够在无需类型定义的情况下直接表示高阶类型。

```scala
[X, Y] =>> Map[Y, X]
```

例如，上面表示了一个双参数的类型构造器，它将参数 `X` 和 `Y` 映射至 `Map[Y, X]`。
类型 Lambda 的类型参数可以有边界，但不能携带 `+` 或 `-` variance 标注。

[更多细节](./type-lambdas-spec.md){: .btn .btn-purple }
