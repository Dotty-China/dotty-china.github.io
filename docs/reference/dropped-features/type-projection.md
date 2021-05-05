---
layout: default
title: "已弃用：通用类型投影"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 4
---

# {{ page.title }}

到目前位置，Scala 允许通用类型投影 `T#A`，其中 `T` 是任意类型，
`A` 是 `T` 中类型成员的名称。

Scala 3 不允许 `T` 为抽象类型时的类型投影。做出该更改的原因是不受限的类型投影是 
[unsound](https://github.com/lampepfl/dotty/issues/1050) 的。

这个限制阻止了 [combinator calculus 的类型级编码](https://michid.wordpress.com/2010/01/29/scala-type-level-encoding-of-the-ski-calculus/)。

要重写使用了抽象类型上的类型投影的代码，请考虑路径依赖类型或隐式参数。
