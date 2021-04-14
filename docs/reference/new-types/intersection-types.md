---
layout: default
title: 交集类型
parent: 新类型
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

在类型上，`&` 操作符创建一个交集类型（intersection type）。

## 类型检查

类型 `S & T` 表示同时属于类型 `S` 和 `T` 的值。

```scala
trait Resettable:
   def reset(): Unit

trait Growable[T]:
   def add(t: T): Unit

def f(x: Resettable & Growable[String]) =
   x.reset()
   x.add("first")
```

参数 `x` 必须*同时*是类型 `Resettable` 和 `Growable[String]` 的值。

交集类型 `A & B` 的成员是 `A` 的所有成员和 `B` 的所有成员。
例如 `Resettable & Growable[String]` 具有成员方法 `reset` 和 `add`。


`&` 是*可交换的*：`A & B` 与 `B & A` 是相同的类型。

如果一个成员同时出现在 `A` 和 `B` 中，则它在 `A & B` 中的类型是其在 `A` 中的类型与其在 `B` 中类型的交集。
例如，假设定义如下：

```scala
trait A:
   def children: List[A]

trait B:
   def children: List[B]

val x: A & B = new C
val ys: List[A & B] = x.children
```

`A & B` 中的 `children` 的类型是 `A` 和 `B` 中 `children` 类型的交集，即 `List[A] & List[B]`。
因为 `List` 是协变的，所以它能够进一步简化为 `List[A & B]`。

One might wonder how the compiler could come up with a definition for
`children` of type `List[A & B]` since what is given are `children`
definitions of type `List[A]` and `List[B]`. The answer is the compiler does not
need to. `A & B` is just a type that represents a set of requirements for
values of the type. At the point where a value is _constructed_, one
must make sure that all inherited members are correctly defined.
So if one defines a class `C` that inherits `A` and `B`, one needs
to give at that point a definition of a `children` method with the required type.

```scala
class C extends A, B:
   def children: List[A & B] = ???
```


[更多细节](./intersection-types-spec.md){: .btn .btn-purple }
