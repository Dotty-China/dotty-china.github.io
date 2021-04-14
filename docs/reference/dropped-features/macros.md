---
layout: default
title: "已弃用：Scala 2 宏"
parent: 已弃用的特性
grand_parent: 参考
nav_order: 2
---

The previous, experimental macro system has been dropped.

Instead, there is a cleaner, more restricted system based on two complementary concepts: `inline` and `'{ ... }`/`${ ... }` code generation.
`'{ ... }` delays the compilation of the code and produces an object containing the code, dually `${ ... }` evaluates an expression which produces code and inserts it in the surrounding `${ ... }`.
In this setting, a definition marked as inlined containing a `${ ... }` is a macro, the code inside the `${ ... }` is executed at compile-time and produces code in the form of `'{ ... }`.
Additionally, the contents of code can be inspected and created with a more complex reflection API as an extension of `'{ ... }`/`${ ... }` framework.

* `inline` has been [implemented](../metaprogramming/inline.md) in Scala 3.
* Quotes `'{ ... }` and splices `${ ... }` has been [implemented](../metaprogramming/macros.md) in Scala 3.
* [TASTy reflect](../metaprogramming/reflection.md) provides more complex tree based APIs to inspect or create quoted code.
