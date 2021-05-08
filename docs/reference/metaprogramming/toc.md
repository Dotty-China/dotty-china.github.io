---
layout: default
title: 概述
parent: 元编程
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

下面几个页面中将介绍重新设计后的 Scala 元编程。它们引入了以下基本设施：

1. [`inline`](./inline.md) 是一个新的修饰符，它保证定义在使用时被内联。
   内联的主要目的是用来减少函数调用与值访问背后的开销。
   展开由 Scala 编译器在 Typer 编译器阶段中执行。与其他一些 ecosystems 中的内联不同，
   Scala 中的 inline 不仅仅是对编译器的请求，而是一个命令。
   这是因为 Scala 中的内联可以驱动其他编译时操作，譬如内联模式匹配（启用类型级编程）、
   宏（enabling compile-time, generative, metaprogramming）

1. [`inline`](./inline.md) is a new modifier that guarantees that
   a definition will be inlined at the point of use. The primary motivation
   behind inline is to reduce the overhead behind function calls and access to
   values. The expansion will be performed by the Scala compiler during the
   `Typer` compiler phase. As opposed to inlining in some other ecosystems,
   inlining in Scala is not merely a request to the compiler but is a
   _command_. The reason is that inlining in Scala can drive other compile-time
   operations, like inline pattern matching (enabling type-level
   programming), macros (enabling compile-time, generative, metaprogramming) and
   runtime code generation (multi-stage programming).

2. [Macros](./macros.md) are built on two well-known fundamental
   operations: quotation and splicing.  Quotation converts program code to
   data, specifically, a (tree-like) representation of this code. It is
   expressed as `'{...}` for expressions and as `'[...]` for types. Splicing,
   expressed as `${ ... }`, goes the other way: it converts a program's representation
   to program code. Together with `inline`, these two abstractions allow
   to construct program code programmatically.

3. [Runtime Staging](./staging.md) Where macros construct code at _compile-time_,
   staging lets programs construct new code at _runtime_. That way,
   code generation can depend not only on static data but also on data available at runtime. This splits the evaluation of the program in two or more phases or ...
   stages. Consequently, this method of generative programming is called "Multi-Stage Programming". Staging is built on the same foundations as macros. It uses
   quotes and splices, but leaves out `inline`.

4. [Reflection](./reflection.md) Quotations are a "black-box"
   representation of code. They can be parameterized and composed using
   splices, but their structure cannot be analyzed from the outside. TASTy
   reflection gives a way to analyze code structure by partly revealing the representation type of a piece of code in a standard API. The representation
   type is a form of typed abstract syntax tree, which gives rise to the `TASTy`
   moniker.

5. [TASTy Inspection](./tasty-inspect.md) Typed abstract syntax trees are serialized
   in a custom compressed binary format stored in `.tasty` files. TASTy inspection allows
   to load these files and analyze their content's tree structure.

