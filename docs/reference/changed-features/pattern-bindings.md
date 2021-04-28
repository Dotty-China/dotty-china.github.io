---
layout: default
title: 模式绑定
parent: 其他变化的特性
grand_parent: 参考
nav_order: 13
---

# {{ page.title }}

Scala 2 中，`val` 定义和 `for` 表达式中的模式绑定是宽松类型的。
在编译时会接受可能失败的匹配，但可能影响程序的运行时行为。
从 Scala 3.1 开始，类型检查规则将会更加严格，会在编译时报出警告。

## 模式定义中的绑定

```scala
val xs: List[Any] = List(1, 2, 3)
val (x: String) :: _ = xs   // error: pattern's type String is more specialized
                            // than the right-hand side expression's type Any
```

这段代码在 Scala 3.1（以及 Scala 3.0 中的 `-source future` 选项下）会给出编译时警告，
而 Scala 2 中它会在运行时失败并抛出 `ClassCastException`。
Scala 3.1 中，只有模式是*不会失败（irrefutable）*的（右侧表达式的类型符合模式的类型）情况下才允许使用模式绑定。
例如，这样可以的：

```scala
val pair = (1, true)
val (x, y) = pair
```

有时用户可能想无论如何都要解构数据，即使模式可能失败。
例如，在知道列表 `elems` 非空时，想要这样解构它：

```scala
val first :: rest = elems   // error
```

这在 Scala 2 中有效。事实上这是 Scala 2 规则的典型用例。
但在 Scala 3.1 中这会给出一个警告。可以在右侧使用 `@unchecked` 注解避免产生警告：

```scala
val first :: rest = elems: @unchecked   // OK
```

这会让编译器接受这个模式绑定。如果 `elems` 不能为空的基本假设是错误的，
这会在运行时给出一个错误。

## `for` 表达式中的模式绑定

类似的变化也适用于 `for` 表达式中的模式。例如：

```scala
val elems: List[Any] = List((1, 2), "hello", (3, 4))
for (x, y) <- elems yield (y, x) // error: pattern's type (Any, Any) is more specialized
                                 // than the right-hand side expression's type Any
```

这段代码在 Scala 3.1 中会给出一个编译时警告，
而在 Scala 2 中列表 `elems` 的元素会被过滤，
只保留能够与模式 `(x, y)` 匹配的元组类型的元素。
在 Scala 3 中可以加上 `case` 前缀获得过滤的功能：

```scala
for case (x, y) <- elems yield (y, x)  // returns List((2, 1), (4, 3))
```

## 语法变化

表达式中的生成器可以以 `case` 作为前缀。
```
Generator      ::=  [‘case’] Pattern1 ‘<-’ Expr
```

## 迁移

Scala 3.0 支持这种新语法。但是，为了在 Scala 2 与 Scala 3 之间实现平滑的交叉编译，
只有在 `-source future` 选项下才会启用变化后的行为和附加的类型检查。
Scala 3.1 中它们会被默认启用。
