---
layout: default
title: "已删除：Symbol 字面量"
parent: 已删除的特性
grand_parent: 参考
nav_order: 12
---

# {{ page.title }}

Symbol 字面量不再被支持。

类 `scala.Symbol` 依然存在，符号字面量 `'xyz` 可以直译为 `Symbol("xyz")`。
但是，推荐使用纯字符串字面量 `"xyz"` 作为替代。
（类 `Symbol` 在未来将被弃用和删除）
