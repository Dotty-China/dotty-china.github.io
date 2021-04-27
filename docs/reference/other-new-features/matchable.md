---
layout: default
title: Matchable Trait
parent: 其他新特性
grand_parent: 参考
nav_order: 9
---

# `Matchable` Trait

新的 trait `Matchable` 控制模式匹配的能力。

## 一个问题

Scala 3 标准库中有一个不可变的数组类型 `IArray`，其定义类似这样：

```scala
  opaque type IArray[+T] = Array[_ <: T]
```

`IArray` 类型提供了 `length` 和 `apply` 扩展方法，但不提供 `update`；因此 `IArray` 类型的值似乎无法更新。

但是，由于模式匹配，存在一个潜在的漏洞。考虑这段代码：

```scala
val imm: IArray[Int] = ...
imm match {
   case a: Array[Int] => a(0) = 1
}
```

测试将在运行时成功，因为 `IArray` 在运行时被表示为 `Array`。但如果我们允许这段代码，
它将破坏不可变数组的基本抽象。

**旁白**：用户也可以使用强制类型转换达到类似的效果：

```scala
imm.asInstanceOf[Array[Int]](0) = 1
```

但这不是一个很大的问题，因为 Scala 中 `asInstanceOf` 被认为是低级的和不安全的。
但是与之不同，编译时没有警告或错误的模式匹配不应该破坏抽象。

还要注意的是，这个问题不是作为 match selector 的不透明类型造成的。
The following slight variant with a value of parametric type `T` as match selector leads to the same problem:

```scala
def f[T](x: T) = x match {
   case a: Array[Int] => a(0) = 0
}
f(imm)
```

最后，请注意这个问题不仅仅与不透明类型相关。任何无界定类型参数或抽象类型都不应该使用模式匹配解构。

## 解决办法

一个新的类型 `scala.Matchable` 可以控制模式匹配。当使用带有构造器模式 `C(...)` 或类型模式 `_: C` 的模式匹配时，
需要模式匹配 selector 符合 `Matchable`。如果不是这样则会发出警告。例如编译本节开头的示例时，我们会得到：

```
> sc ../new/test.scala -source future
-- Warning: ../new/test.scala:4:12 ---------------------------------------------
4 |    case a: Array[Int] => a(0) = 0
  |            ^^^^^^^^^^
  |            pattern selector should be an instance of Matchable,
  |            but it has unmatchable type IArray[Int] instead
```

为了允许从 Scala 2 中迁移，以及在 Scala 2 和 3 之间交叉编译，
只会在 `-source future-migration` 或更高时打开警告。

`Matchable` 是一个 universal trait，其父类为 `Any`。它被 `AnyVal` 和 `Object` 继承。
因为 `Matchable` 是所有具体类或引用类型的父类型，这意味着这些类的实例可以像以前一样进行匹配。
但是，下列类型的值作为匹配 selector 将会发出警告：

- 类型 `Any`：如果需要模式匹配，则应该使用 `Matchable` 替代。
- 无界限类型参数和抽象类型：如果需要模式匹配，则它们应该具有上界 `Matchable`。
- 只有 universal trait 作为界限的类型参数和抽象类型：同样的，应该把 `Matchable` 加入界限。

下面是定义类和 trait 及其定义的方法的层次结构：

```scala
abstract class Any {
   def getClass
   def isInstanceOf
   def asInstanceOf
   def ==
   def !=
   def ##
   def equals
   def hashCode
   def toString
}

trait Matchable extends Any

class AnyVal extends Any, Matchable
class Object extends Any, Matchable
```

`Matchable` 目前是没有任何方法的标记 trait。随着时间推移，
我们可能将 `getClass` 和 `isInstanceOf` 方法迁移到其中，因为它们与模式匹配密切相关。

## `Matchable` 与 Universal Equality

Methods that pattern-match on selectors of type `Any` will need a cast once the
Matchable warning is turned on. The most common such method is the universal
`equals` method. It will have to be written as in the following example:

```scala
class C(val x: String) {
   override def equals(that: Any): Boolean =
      that.asInstanceOf[Matchable] match
         case that: C => this.x == that.x
         case _ => false
}
```

The cast of `that` to `Matchable` serves as an indication that universal equality
is unsafe in the presence of abstract types and opaque types since it cannot properly distinguish the meaning of a type from its representation. The cast
is guaranteed to succeed at run-time since `Any` and `Matchable` both erase to
`Object`.

For instance, consider the definitions

```scala
opaque type Meter = Double
def Meter(x: Double) = x

opaque type Second = Double
def Second(x: Double) = x
```

Here, universal `equals` will return true for

```scala
   Meter(10).equals(Second(10))
```

even though this is clearly false mathematically. With [multiversal equality](../contextual/multiversal-equality.md) one can mitigate that problem somewhat by turning

```scala
   Meter(10) == Second(10)
```

into a type error.
