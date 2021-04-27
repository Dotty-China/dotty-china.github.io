---
layout: default
title: 依赖函数类型
parent: 新类型
grand_parent: 参考
nav_order: 5
---

# {{ page.title }}

依赖函数类型（Dependent Function Type）是结果类型依赖函数参数的函数类型。例如：

```scala
trait Entry { type Key; val key: Key }

def extractKey(e: Entry): e.Key = e.key          // a dependent method

val extractor: (e: Entry) => e.Key = extractKey  // a dependent function value
//             ^^^^^^^^^^^^^^^^^^^
//             a dependent function type
```

Scala 已经有了*依赖方法（Dependent Method）*，即结果类型引用方法某些参数的方法。方法 `extractKey` 就是一个例子。
它的结果类型 `e.Key` 引用了它的参数 `e`（我们也称 `e.Key` *依赖* `e`）。但目前为止，我们还无法将这些方法转换为函数值，
以便将它们作为参数传递给其他函数，或者作为结果返回。依赖方法不能简单地转化为函数，因为没有类型可以描述它们。

现在在 Scala 3 中，这是可能的。上述的值 `extractor` 的类型是

```scala
(e: Entry) => e.Key
```

这个类型描述了接受任意 `Entry` 类型的参数 `e`，并返回类型为 `e.Key` 的值的函数值。

回想一下，普通的函数类型 `A => B` 表示为 [`Function1` trait](https://dotty.epfl.ch/api/scala/Function1.html) 
的一个实例，具有更多参数的方法也用类似的方式来表示。依赖函数被表示为这些特质的实例，但它们得到了额外的 refinement。
事实上，上述的依赖函数类型只是

```scala
Function1[Entry, Entry#Key] {
   def apply(e: Entry): e.Key
}
```

的语法糖。

[更多细节](./dependent-function-types-spec.md){: .btn .btn-purple }
