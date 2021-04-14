---
layout: default
title: 类型 Lambda
parent: 新类型
grand_parent: 参考
nav_order: 3
---

A _type lambda_ lets one express a higher-kinded type directly, without
a type definition.

```scala
[X, Y] =>> Map[Y, X]
```

For instance, the type above defines a binary type constructor, which maps arguments `X` and `Y` to `Map[Y, X]`.
Type parameters of type lambdas can have bounds, but they cannot carry `+` or `-` variance annotations.

[More details](./type-lambdas-spec.md)
