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

 1. 隐式的功能很强大，很容易被滥用和误用。This observation holds in almost all cases when we talk about _implicit conversions_，尽管隐式转换在概念上不同，但它与其他隐式定义共享相同的语法，
    例如，关于这两个定义：

    ```scala
    implicit def i1(implicit x: T): C[T] = ...
    implicit def i2(x: T): C[T] = ...
    ```
    
    第一个是条件隐式*值*，第二个是隐式*转换*。条件隐式值是表达 type class 的基础，whereas most applications of implicit conversions have turned out to be of dubious value。
    问题是，很多语言的新手都是从定义隐式转换开始的，因为隐式转换很容易理解，而且看起来很强大便捷。
    Scala 3 把定义在其他地方的类型之间的“undisciplined”隐式的定义与应用置于一个 language flag 之下。
    这是阻止隐式转换的滥用的有效步骤。但问题依然存在，在语法上隐式转换和隐式值看起来太相似了。
 
 2. 另一个普遍的滥用是过度依赖隐式导入。这常常会导致难以理解的类型错误，这些错误随着正确的导入魔咒消失，只留下挫败感。
    相反，很难看到程序使用了哪个隐式，因为隐式可以隐藏在一长串导入中的任何地方。 

 3. 隐式定义的语法太少。它仅由一个修饰符 `implicit` 构成，这个修饰符能够附加到大量语言结构上。
    对于新手而言，这样做的一个问题是，它传递的是机制而不是意图。
    例如，一个 type class 实例在无条件限制时是一个隐式对象或 val，有条件限制时是一个隐式 def，其隐式参数引用某个类。
    这精确的描述了隐式定义会被翻译为什么——只需要去掉隐式修饰符。但对定义目的的提示时相当间接的，很容易被误读，正如上文中 `i1` 和 `i2` 的定义那样。

 4. 隐式参数的语法也有缺点。虽然隐式参数的*形参*是明确指定的，但*实参*不是。把实际参数作为隐式参数传递的语法语法看起来类似常规应用 `f(args)`。
    这是有问题的，因为这意味着在调用时具体要传递哪个参数有可能会混淆。例如，对于这个定义
    
    ```scala
    def currentMap(implicit ctx: Context): Map[String, Int]
    ```

    不能使用 `currentMap("abc")`，因为字符串 `"abc"` 会作为隐式参数 `ctx` 传递。用户必须写成 `currentMap.apply("abc")` 作为替代，
    这不方便也不规则。出于同样的原因，一个方法定义只能有一个隐式参数部分，并且始终位于最后。这种限制不仅减少了 orthogonality，
    而且还阻止了一些有用的程序构造，例如带有一个普通参数的方法，其类型依赖于隐式值。
    最后，隐式参数必须有一个名称也会造成一些烦恼，很多情况下这个名称从未被引用。

 5. 隐式对各种工具提出了挑战。可用的隐式取决于上下文，因此命令补全必须考虑上下文。
    这在 IDE 中是可行的，但 Scaladoc 这样基于静态网页的工具只能提供 approximation。
    另一个问题是，隐式搜索失败通常会给出很不具体的错误消息，特别是一些深度递归的隐式搜索。
    注意 Scala 3 编译器已经在错误诊断领域取得了很大进展。如果递归搜索在某些层级失败，
    它将显式结构的内容和缺少的内容。此外，它还可以会提出能够将缺失隐式值带入作用域的 import 建议。

这是缺点都不是致命的，毕竟隐式的运用非常广泛，很多库和程序都依赖它们。
但是它们一起使得使用隐式的代码变得更麻烦、更不清晰。

从历史上来看，这些缺点很多都来自于在 Scala 中逐渐“发现”的方式。Scala 最初只有隐式转换，其预期用法是在定义类和 trait 后“扩展”它们。
隐式参数和实例定义在 2006 年后出现，我们选择了类似的语法，因为它看起来很方便。出于同样的原因，
我们没有努力区分隐式导入和隐式传参与对应的非隐式用法。

现有的 Scala 程序员基本习惯了现状，认为没有什么需要改变的。但是对于新用户来说，这种现状是一大障碍。
我相信，如果我们想克服这个障碍，我们应该后退一步，考虑一个全新的设计。

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
