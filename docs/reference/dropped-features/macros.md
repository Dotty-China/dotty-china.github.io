---
layout: default
title: "已弃用：Scala 2 宏"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

过去实验性的宏系统已经被删除。

作为替代，现在有一个更干净、更受限的系统，它基于两个互补的概念：`inline` 与 `'{ ... }`/`${ ... }` 代码生成。
`'{ ... }` 延迟对代码的编译，并生成包含代码的对象，
dually `${ ... }` evaluates an expression which produces code and inserts it in the surrounding `${ ... }`。
In this setting, a definition marked as inlined containing a `${ ... }` is a macro, the code inside the `${ ... }` is executed at compile-time and produces code in the form of `'{ ... }`.
Additionally, the contents of code can be inspected and created with a more complex reflection API as an extension of `'{ ... }`/`${ ... }` framework.

* `inline` has been [implemented](../metaprogramming/inline.md) in Scala 3.
* Quotes `'{ ... }` and splices `${ ... }` has been [implemented](../metaprogramming/macros.md) in Scala 3.
* [TASTy reflect](../metaprogramming/reflection.md) provides more complex tree based APIs to inspect or create quoted code.
