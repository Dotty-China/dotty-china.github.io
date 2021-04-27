---
layout: default
title: 并集类型
parent: 新类型
grand_parent: 参考
nav_order: 2
---

# {{ page.title }}

并集类型 `A | B` 包括类型 `A` 与类型 `B` 的所有值。

```scala
case class UserName(name: String)
case class Password(hash: Hash)

def help(id: UserName | Password) = {
   val user = id match
      case UserName(name) => lookupName(name)
      case Password(hash) => lookupPassword(hash)
   ...
}
```

并集类型是交集类型的对偶。`|` 是*可交换的*：`A | B` 与 `B | A` 是相同的类型。

只有在显式指定并集类型时，编译器才会将交集类型指定给表达式。
这可以在下面的 [REPL](https://docs.scala-lang.org/overviews/repl/overview.html) transcript 
中观察到：

```scala
scala> val password = Password(123)
val password: Password = Password(123)

scala> val name = UserName("Eve")
val name: UserName = UserName(Eve)

scala> if true then name else password
val res2: Object & Product = UserName(Eve)

scala> val either: Password | UserName = if true then name else password
val either: Password | UserName = UserName(Eve)
```

`res2` 的类型是 `Object & Product`，是 `UserName` 和 `Password` 的超类型，但不是最小超类型 
`Password | UserName`。如果我们想要最小的超类型，我们必须显式给出它，as is done for the type of `either`。

[更多细节](./union-types-spec.md){: .btn .btn-purple }
