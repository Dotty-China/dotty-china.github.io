---
layout: default
title: Trait 参数
parent: 其他新特性
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

Scala 3 允许 trait 拥有参数，就像类能拥有参数一样。

```scala
trait Greeting(val name: String) {
   def msg = s"How are you, $name"
}

class C extends Greeting("Bob") {
   println(msg)
}
```

传递给 trait 的参数在 trait 初始化之前立即计算。

trait 参数的一个潜在问题是如何防止歧义。例如，您可以使用不同参数继承 `Greeting` 两次。

```scala
class D extends C, Greeting("Bill") // error: parameter passed twice
```

这会打印“Bob”还是“Bill”？事实上，此程序是非法的，因为它违背了以下 trait 规则中的第二条：

 1. 如果 `C` 继承了一个参数化 trait `T`，而它的超类没有，则 `C` *必须*传递参数给 `T`。
 
 2. 如果 `C` 继承了一个参数化 trait `T`，而它的超类也继承了，则 `C` *不能*传递参数给 `T`。

 3. trait 不能传递参数给父 trait。


这里有一个 trait 继承了参数化 trait `Greeting`。

```scala
trait FormalGreeting extends Greeting {
   override def msg = s"How do you do, $name"
}
```

根据规则的需求，这里不向 `Greeting` 传递参数。但是，在定义继承 `FormalGreeting` 的类时，
这会带来一个问题：

```scala
class E extends FormalGreeting // error: missing arguments for `Greeting`.
```

编写 `E` 的正确方法是同时继承 `Greeting` 和 `FormalGreeting`（按任意顺序）：

```scala
class E extends Greeting("Bob"), FormalGreeting
```

### 具有上下文参数的 trait

如果 trait 只包含[上下文参数](../contextual/using-clauses)，则这个“需要显式继承”的规则被放宽。
这种情况下，the trait reference is implicitly inserted as an additional parent with inferred arguments。
例如，下面是 `Greeting` 的一个变体，其中 addressee 是 `ImpliedName` 类型的上下文参数：

```scala
case class ImpliedName(name: String) {
  override def toString = name
}

trait ImpliedGreeting(using val iname: ImpliedName) {
   def msg = s"How are you, $iname"
}

trait ImpliedFormalGreeting extends ImpliedGreeting {
   override def msg = s"How do you do, $iname"
}

class F(using iname: ImpliedName) extends ImpliedFormalGreeting
```

最后一行中的定义 `F` 被隐式展开为

```scala
class F(using iname: ImpliedName) extends
   Object,
   ImpliedGreeting(using iname),
   ImpliedFormalGreeting(using iname)
```

注意，这里插入了对超 trait `ImpliedGreeting` 的引用，即使并未显式提及它。

## 参考

更多细节请参考 [Scala SIP 25](http://docs.scala-lang.org/sips/pending/trait-parameters.html)。
