---
layout: default
title: "已删除：private[this] 和 protected[this]"
parent: 已删除的特性
grand_parent: 参考
nav_order: 16
---

# {{ page.title }}

`private[this]` 和 `protected[this]` 访问修饰符已经被弃用，将被逐步淘汰。

以前，这些修饰符需要用来

 - 避免生成 getter 和 setter
 - excluding code under a `private[this]` from variance checks. (Scala 2 also excludes `protected[this]` but this was found to be unsound and was therefore removed).

The compiler now infers for `private` members the fact that they are only accessed via `this`. Such members are treated as if they had been declared `private[this]`. `protected[this]` is dropped without a replacement.

