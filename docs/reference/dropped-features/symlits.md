---
layout: default
title: "已弃用：Symbol 字面量"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 12
---

Symbol literals are no longer supported.

The `scala.Symbol` class still exists, so a
literal translation of the symbol literal `'xyz` is `Symbol("xyz")`. However, it is recommended to use a plain string literal `"xyz"` instead. (The `Symbol` class will be deprecated and removed in the future).
