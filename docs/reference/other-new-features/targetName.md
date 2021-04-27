---
layout: default
title: "@targetName 注解"
parent: 其他新特性
grand_parent: 参考
nav_order: 11
---

# `@targetName` 注解

定义上的 `@targetName` 注解定义了该实现的候补名称。例如：

```scala
import scala.annotation.targetName

object VecOps {
   extension [T](xs: Vec[T]) {
      @targetName("append")
      def ++= [T] (ys: Vec[T]): Vec[T] = ...
   }
}
```

这里 `++=` 操作符使用 `append` 名称实现（在字节码或本机代码中）。实现名称影响生成的代码，
并且其他语言的代码可以使用这个名称调用该方法。例如，这个 `++=` 可以在 Java 中像这样调用：

```java
VecOps.append(vec1, vec2)
```

`@targetName` 注解与在 Scala 中的用法无关。Scala 中的对该函数的调用只能使用 `++=`，而不是 `append`。

## 细节

 1. `@targetName` 定义在包 `scala.annotation` 中。它接受一个 `String` 类型的参数。
    该字符串称为被注释定义的*外部名称（External Name）*。

 2. 可以为任意种类的定义提供 `@targetName` 注解。

 3. `@targetName` 注解中给定的名称必须是宿主平台上实体的合法名称。

 4. 建议使用符号作为名称的定义带有 `@targetName` 注解。这将设立一个更易于搜索的备用名称，
    并且避免运行时诊断时出现晦涩的编码。

 5. 名称在宿主平台不合法的定义也应该带有 `@targetName` 注解。

## 与覆盖的关系

`@targetName` 注解对于匹配两个方法定义以确定它们是否冲突或者重写另一个非常重要。
如果两个方法定义具有相同的名称、签名以及擦除后的名称，则它们相匹配。在这里，

- 定义的*签名*由所有（值）参数类型与返回值类型的擦除名称组成。
- 方法定义的*擦除后名称（Erased Name）*在具有 `@targetName` 注解时为其外部名称，否则为定义的名称。

这意味着 `@targetName` 注解可以用来消除两个方法定义之间的歧义。例如：

```scala
def f(x: => String): Int = x.length
def f(x: => Int): Int = x + 1  // error: double definition
```

上面的两个定义冲突，因为它们擦除后的参数类型都是由按名参数翻译而来的 `Function0`。
因此它们拥有相同的名称和签名。但我们可以为它们中至少一个添加 `@targetName` 注解来避免冲突。
例如：

```scala
@targetName("f_string")
def f(x: => String): Int = x.length
def f(x: => Int): Int = x + 1  // OK
```

这将在生成的代码中提供方法 `f_string` 和 `f`。

但是，`@targetName` 注解不允许打破具有相同名称和类型的两个定义之间的重写关系。
所以下面的代码是错误的：

```scala
import annotation.targetName
class A {
   def f(): Int = 1
}
class B extends A {
   @targetName("g") def f(): Int = 2
}
```

编译器会在此报告：

```
-- Error: test.scala:6:23 ------------------------------------------------------
6 |  @targetName("g") def f(): Int = 2
  |                       ^
  |error overriding method f in class A of type (): Int;
  |  method f of type (): Int should not have a @targetName
  |  annotation since the overridden member hasn't one either
```

相关的重写规则可以概括如下：

- 如果两个成员的名称和签名相同，并且它们具有相同的擦除后名称或相同的类型，则可以互相重写。
- 如果两个成员之间存在重写关系，则他们的擦除后名称和类型必须相同。

通常来说，生成代码中的所有重写关系也必须存在于原始代码中。所以下面的示例也会发生错误：

```scala
import annotation.targetName
class A {
   def f(): Int = 1
}
class B extends A {
   @targetName("f") def g(): Int = 2
}
```

在这里，原始方法 `g` 和 `f` 之间没有重写关系，因为它们具有相同的名称。
但是当切换到目标名称后，编译器就会报告冲突；

```
-- [E120] Naming Error: test.scala:4:6 -----------------------------------------
4 |class B extends A:
  |      ^
  |      Name clash between defined and inherited member:
  |      def f(): Int in class A at line 3 and
  |      def g(): Int in class B at line 5
  |      have the same name and type after erasure.
1 error found
```
