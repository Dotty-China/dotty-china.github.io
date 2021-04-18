---
layout: default
title: 概述
parent: 上下文抽象
grand_parent: 参考
nav_order: 1
---

# {{ page.title }}

## 对现状的批判

Scala 的隐式是它最具特色的特性。它们是对上下文进行抽象的基本方法。
它们代表了一个统一的样式，有各式各样的用例，其中包括：
实现 type class、建立上下文、依赖注入、expressing capabilities、计算新类型以及证明它们之间的关系。

继 Haskell 之后，Scala 是第二个具有某种形式隐式的流行语言。其他语言也纷纷效仿。
例如 [Rust 的 traits](https://doc.rust-lang.org/rust-by-example/trait.html)以及 
[Swift 的 protocol extensions](https://docs.swift.org/swift-book/LanguageGuide/Protocols.html#ID521)。
Kotlin 的 [编译时依赖解析](https://github.com/Kotlin/KEEP/blob/e863b25f8b3f2e9b9aaac361c6ee52be31453ee0/proposals/compile-time-dependency-resolution.md)、
C# 的 [Shapes and Extensions](https://github.com/dotnet/csharplang/issues/164)、
F# 的 [Trait](https://github.com/MattWindsor91/visualfsharp/blob/hackathon-vs/examples/fsconcepts.md) 等设计建议也在计划中。
隐式也是 [Coq](https://coq.inria.fr/refman/language/extensions/implicit-arguments.html)、[Agda](https://agda.readthedocs.io/en/latest/language/implicit-arguments.html) 
等定理证明器的一个共同特征。

尽管这些设计使用了完全不同的术语，但它们都是 term inference 核心思想的变体。给定一个类型，
编译器合成一个具有该类型的“canonical” term。Scala 以比大多数语言更纯粹的形式体现了这一思想：
隐式参数直接引发推断参数，也可以显式写出。相比之下，基于 type class 的设计则不这么直接，
因为它们把 term inference 隐藏在某种形式的 type classification 背后，
并且不提供显式提供推断值（通常是 dictionaries）的选择。

既然 term inference 是行业发展方向，既然 Scala 以一种非常纯粹的方式拥有它，那么为什么它没有更受欢迎呢？
事实上，隐式同时是 Scala 最突出也是最有争议的特点。我认为很多方面的共同作用使得隐式更难学习且更难防止其滥用。

批评的细节是：

1. Being very powerful, implicits are easily over-used and mis-used. This observation holds in almost all cases when we talk about _implicit conversions_, which, even though conceptually different, share the same syntax with other implicit definitions. For instance, regarding the two definitions

    ```scala
    implicit def i1(implicit x: T): C[T] = ...
    implicit def i2(x: T): C[T] = ...
    ```

   the first of these is a conditional implicit _value_, the second an implicit _conversion_. Conditional implicit values are a cornerstone for expressing type classes, whereas most applications of implicit conversions have turned out to be of dubious value. The problem is that many newcomers to the language start with defining implicit conversions since they are easy to understand and seem powerful and convenient. Scala 3 will put under a language flag both definitions and applications of "undisciplined" implicit conversions between types defined elsewhere. This is a useful step to push back against overuse of implicit conversions. But the problem remains that syntactically, conversions and values just look too similar for comfort.

 2. Another widespread abuse is over-reliance on implicit imports. This often leads to inscrutable type errors that go away with the right import incantation, leaving a feeling of frustration. Conversely, it is hard to see what implicits a program uses since implicits can hide anywhere in a long list of imports.

 3. The syntax of implicit definitions is too minimal. It consists of a single modifier, `implicit`, that can be attached to a large number of language constructs. A problem with this for newcomers is that it conveys mechanism instead of intent. For instance, a type class instance is an implicit object or val if unconditional and an implicit def with implicit parameters referring to some class if conditional. This describes precisely what the implicit definitions translate to -- just drop the `implicit` modifier, and that's it! But the cues that define intent are rather indirect and can be easily misread, as demonstrated by the definitions of `i1` and `i2` above.

 4. The syntax of implicit parameters also has shortcomings. While implicit _parameters_ are designated specifically, arguments are not. Passing an argument to an implicit parameter looks like a regular application `f(arg)`. This is problematic because it means there can be confusion regarding what parameter gets instantiated in a call. For instance, in

    ```scala
    def currentMap(implicit ctx: Context): Map[String, Int]
    ```

    one cannot write `currentMap("abc")` since the string `"abc"` is taken as explicit argument to the implicit `ctx` parameter. One has to write `currentMap.apply("abc")` instead, which is awkward and irregular. For the same reason, a method definition can only have one implicit parameter section and it must always come last. This restriction not only reduces orthogonality, but also prevents some useful program constructs, such as a method with a regular parameter whose type depends on an implicit value. Finally, it's also a bit annoying that implicit parameters must have a name, even though in many cases that name is never referenced.

 5. Implicits pose challenges for tooling. The set of available implicits depends on context, so command completion has to take context into account. This is feasible in an IDE but tools like [Scaladoc](https://docs.scala-lang.org/overviews/scaladoc/overview.html) that are based on static web pages can only provide an approximation. Another problem is that failed implicit searches often give very unspecific error messages, in particular if some deeply recursive implicit search has failed. Note that the Scala 3 compiler has already made a lot of progress in the error diagnostics area. If a recursive search fails some levels down, it shows what was constructed and what is missing. Also, it suggests imports that can bring missing implicits in scope.

None of the shortcomings is fatal, after all implicits are very widely used, and many libraries and applications rely on them. But together, they make code using implicits a lot more cumbersome and less clear than it could be.

Historically, many of these shortcomings come from the way implicits were gradually "discovered" in Scala. Scala originally had only implicit conversions with the intended use case of "extending" a class or trait after it was defined, i.e. what is expressed by implicit classes in later versions of Scala. Implicit parameters and instance definitions came later in 2006 and we picked similar syntax since it seemed convenient. For the same reason, no effort was made to distinguish implicit imports or arguments from normal ones.

Existing Scala programmers by and large have gotten used to the status quo and see little need for change. But for newcomers this status quo presents a big hurdle. I believe if we want to overcome that hurdle, we should take a step back and allow ourselves to consider a radically new design.

## 新的设计

下面的页面将介绍 Scala 中上下文抽象的重新设计。它们带来了四个基本变化：
 
 1. [Given 实例](./givens.md)是定义可以合成的基本 term 的新方法。它们取代了隐式定义。
    该提议的核心原则是不把 `implicit` 修饰符和大量特性混合，而用一种方法定义可以为类型合成的 term。

 2. [Using 子句](./using-clauses.md)是隐式参数以及传递对应参数的新语法。它明确的对其形参和实参，解决了许多语言上的缺陷。
    它还允许我们在第一个定义中有多个 `using` 子句。

 3. [“Given”导入](./given-imports.md)是一类新的 import 选择器，专门导入 given 而不导入其他内容。

 4. [隐式转换](./conversions.md)现在表示为标准 `Conversion` 类的 given 实例。其他形式的隐式转换都被淘汰。

This section also contains pages describing other language features that are related to context abstraction. These are:

 - [Context Bounds](./context-bounds.md), which carry over unchanged.
 - [Extension Methods](./extension-methods.md) replace implicit classes in a way that integrates better with type classes.
 - [Implementing Type Classes](type-classes.md) demonstrates how some common type classes can be implemented using the new constructs.
 - [Type Class Derivation](./derivation.md) introduces constructs to automatically derive type class instances for ADTs.
 - [Multiversal Equality](./multiversal-equality.md) introduces a special type class to support type safe equality.
 - [Context Functions](./context-functions.md) provide a way to abstract over context parameters.
 - [By-Name Context Parameters](./by-name-context-parameters.md) are an essential tool to define recursive synthesized values without looping.
 - [Relationship with Scala 2 Implicits](./relationship-implicits.md) discusses the relationship between old-style implicits and new-style givens and how to migrate from one to the other.

Overall, the new design achieves a better separation of term inference from the rest of the language: There is a single way to define givens instead of a multitude of forms all taking an `implicit` modifier. There is a single way to introduce implicit parameters and arguments instead of conflating implicit with normal arguments. There is a separate way to import givens that does not allow them to hide in a sea of normal imports. And there is a single way to define an implicit conversion which is clearly marked as such and does not require special syntax.

This design thus avoids feature interactions and makes the language more consistent and orthogonal. It will make implicits easier to learn and harder to abuse. It will greatly improve the clarity of the 95% of Scala programs that use implicits. It has thus the potential to fulfil the promise of term inference in a principled way that is also accessible and friendly.

Could we achieve the same goals by tweaking existing implicits? After having tried for a long time, I believe now that this is impossible.

 - First, some of the problems are clearly syntactic and require different syntax to solve them.
 - Second, there is the problem how to migrate. We cannot change the rules in mid-flight. At some stage of language evolution we need to accommodate both the new and the old rules. With a syntax change, this is easy: Introduce the new syntax with new rules, support the old syntax for a while to facilitate cross compilation, deprecate and phase out the old syntax at some later time. Keeping the same syntax does not offer this path, and in fact does not seem to offer any viable path for evolution
 - Third, even if we would somehow succeed with migration, we still have the problem
 how to teach this. We cannot make existing tutorials go away. Almost all existing tutorials start with implicit conversions, which will go away; they use normal imports, which will go away, and they explain calls to methods with implicit parameters by expanding them to plain applications, which will also go away. This means that we'd have
 to add modifications and qualifications to all existing literature and courseware, likely causing more confusion with beginners instead of less. By contrast, with a new syntax there is a clear criterion: Any book or courseware that mentions `implicit` is outdated and should be updated.
