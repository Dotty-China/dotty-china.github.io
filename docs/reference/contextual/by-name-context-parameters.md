---
layout: default
title: 按名上下文参数
parent: 上下文抽象
grand_parent: 参考
nav_order: 12
---

# {{ page.title }}

上下文参数可以按名声明，以避免 divergent inferred expansion。例如：

```scala
trait Codec[T] {
   def write(x: T): Unit
}

given intCodec: Codec[Int] = ???

given optionCodec[T](using ev: => Codec[T]): Codec[Option[T]] with {
   def write(xo: Option[T]) = xo match {
      case Some(x) => ev.write(x)
      case None =>
   }
}

val s = summon[Codec[Option[Int]]]

s.write(Some(33))
s.write(None)
```

与普通的按名参数一样，上下文参数 `ev` 是按需计算的。在上面的例子种，如果 option 值 `x` 是 `None`，
则根本不计算它。

The synthesized argument for a context parameter is backed by a local val
if this is necessary to prevent an otherwise diverging expansion.

合成 `=> T` 类型的按名上下文参数的精确步骤如下所示。

 1. 创建一个新的 `T` 类型 given：
    
    ```scala
    given lv: T = ???
    ```

    其中 `lv` 是一个任意的新名称。
   
 2. 这个 given 不能立即用作参数推断的候选对象（使其立即可用可能会导致合成计算过程中的循环）。
    但它在所有嵌套上下文种都可用，这些嵌套上下文会再次查找按名上下文参数作为参数。

 3. If this search succeeds with expression `E`, and `E` contains references to `lv`, replace `E` by

    ```scala
    { given lv: T = E; lv }
    ```

    Otherwise, return `E` unchanged.


在上面的例子中，`s` 的定义将被展开如下:

```scala
val s = summon[Test.Codec[Option[Int]]](
   optionCodec[Int](using intCodec)
)
```

没有生成局部 given 实例，因为合成的参数不是递归的。

## 参考

更多细节请参见 [Issue #1998](https://github.com/lampepfl/dotty/issues/1998)
以及相关的 [Scala SIP](https://docs.scala-lang.org/sips/byname-implicits.html).
