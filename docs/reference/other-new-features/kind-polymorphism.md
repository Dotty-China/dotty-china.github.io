---
layout: default
title: Kind 多态
parent: 其他新特性
grand_parent: 参考
nav_order: 8
---

# {{ page.title }}

Scala 中的类型参数通常被划为不同的 *kind*。第一级类型是值的类型。高阶类型是类似 `List` 和 `Map` 这样的类型构造器。


The kind of a type is indicated by the top type of which it is a subtype. 
常规类型是 `Any` 的子类型，像 `List` 这样带有单个协变参数的类型构造器是 `[+X] =>> Any` 的子类型，
像 `Map` 这样的类型构造器是 `[X, +Y] =>> Any` 的子类型。

一个类型只能按照其 kind 被使用。`Any` 的子类型不能接受类型参数，而 `[X] =>> Any` 的子类型*必须*应用于类型参数，
除非传递给同一个 kind 的类型参数。

有时我们希望类型参数能有多种 kind，例如定义一个适用于任何 kind 参数的隐式值。
现在这可以通过使用一种形式的（*子类型*）kind 多态实现。
Kind 多态（Kind Polymorphism）依赖于特殊类型 `scala.AnyKind`，它可以作为类型的上界使用。

```scala
def f[T <: AnyKind] = ...
```

`f` 的实际类型参数可以是任意 kind 的类型。所以以下写法都是合法的：

```scala
f[Int]
f[List]
f[Map]
f[[X] =>> String]
```

我们称类型上界为 `AnyKind` 的类型参数和抽象类型为*any-kinded 类型*。
由于 any-kinded 类型的 kind 位置，因此必须严格限制其使用：
any-kinded 类型既不能为值的类型，nor can it be instantiated with type parameters。
所以 any-kinded 类型唯一能做的就是把它作为实参传递给另一个 any-kinded 类型的形参。
Nevertheless, this is enough to achieve some interesting generalizations that work across kinds, typically
through advanced uses of implicits.

(todo: insert good concise example)

一些技术细节：`AnyKind` 和 `Any` 一样是一个合成出的类，但没有任何成员。它不继承其他类。
它被声明为 `abstract` 和 `final` 的，所以它不能被继承也不能实例化。

`AnyKind` 在 Scala 的子类型系统中扮演着特殊的角色：它是所有类型的超类型，而无论这些类型是什么 kind。
它也假定为于其他类型 kind 兼容。此外，`AnyKind` 被视为高阶类型（因此不能用作值的类型），
但它也没有类型参数（因此不能实例化）。

**注意**：这个特性被认为是实验性质的，但已经很稳定。可以通过编译器参数 `-Yno-kind-polymorphism` 禁用此功能。
