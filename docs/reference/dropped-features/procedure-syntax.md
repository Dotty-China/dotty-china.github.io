---
layout: default
title: "已删除：过程语法"
parent: 已删除的特性
grand_parent: 参考
nav_order: 6
---

# {{ page.title }}

过程语法
```scala
def f() { ... }
```
被删除。需要用以下写法之一替代：

```scala
def f() = { ... }
def f(): Unit = { ... }
```

Scala 3 在 `-source:3.0-migration` 选项下接受旧语法。如果还设置了 `-migration` 选项，
它还可以将旧语法重写为新语法。[Scalafix](https://scalacenter.github.io/scalafix/) 工具
也可以重写过程语法，使其与 Scala 3 兼容。
