---
layout: default
title: 导入 Given
parent: 上下文抽象
grand_parent: 参考
nav_order: 5
---

# {{ page.title }}

import 通配符选择器的一个特殊形式用于导入 given 实例。例如：

```scala
object A:
   class TC
   given tc: TC = ???
   def f(using TC) = ???

object B:
   import A.*
   import A.given
   ...
```

在上面的代码中，对象 `B` 中的 `import A.*` 子句导入 `A` *除了* given 实例 `tc` 的所有成员。
而第二个导入 `import A.given` 只导入 given 实例。两个 import 子句也可以合并为一个：

```scala
object B:
   import A.{given, *}
   ...
```

一般来说，一个普通的通配符选择器 `_` 将除了 given 和扩展外的所有定义带入作用域，
而 `given` 选择器将所有 given（包括那些扩展生成的）带入作用域。

这个规则有两个好处：

- 这让作用域内 given 的来源更清晰。特别是无法在一长串普通通配符导入中隐藏对 given 的导入。
- 这允许导入所有 given 而不导入其他内容。这一点尤其重要，因为 given 可以是匿名的，所以依赖使用命名导入通常不适用。

## 按类型导入

因为 given 可以是匿名的，所以按其名称导入并不总是可行的，通常会使用通配符导入。按类型导入提供了一种比通配符导入更具体的方法，
这也使导入的内容更清晰。例如：

```scala
import A.given TC
```

这会导入 `A` 中任意类型符合 `TC` 的 given。导入多个类型 `T1,...,Tn` 的 given 通过多个 `given` 选择器表示。

```scala
import A.{given T1, ..., given Tn}
```

导入参数化类型的所有 given 实例由通配符参数表示。例如，假设有这样一个对象

```scala
object Instances:
   given intOrd: Ordering[Int] = ...
   given listOrd[T: Ordering]: Ordering[List[T]] = ...
   given ec: ExecutionContext = ...
   given im: Monoid[Int] = ...
```

import 子句

```scala
import Instances.{given Ordering[?], given ExecutionContext}
```

将导入 `intOrd`、`listOrd` 和 `ec` 实例，但忽略 `im` 实例，因为它不符合指定的限制。

按类型导入可以和按名称导入混合使用。如果两者同时存在在同一 import 子句中，则按类型导入排在最后。例如，这个 import 子句

```scala
import Instances.{im, given Ordering[?]}
```

将导入 `im`、`intOrd` 和 `listOrd` 实例，但忽略 `ec`。

## 迁移

上述导入规则的结果是，库必须与所有用户同步地从旧式隐式与普通导入迁移到 given 和 given 导入。

下面的修改避免了这个迁移障碍。

 1. `given` 导入选择器也将旧式隐式引入其作用域。所以 Scala 3.0 中旧式隐式定义可以用 `_` 或 `given` 通配符选择器引入作用域。
 
 2. 在 Scala 3.1 中，使用 `_` 通配符导入访问的旧式隐式会发出弃用警告。
 
 3. 在 Scala 3.1 之后的每个版本中，使用 `_` 通配符导入访问的旧式隐式会发出编译时错误。

这些规则意味着用户在 Scala 3 中可以使用 `given` 选择器访问旧式隐式，并在之后版本中被建议如此，并在更久之后被迫这样做。
库可以在用户这样迁移后切换到 given 实例。

## 语法

```
Import            ::=  ‘import’ ImportExpr {‘,’ ImportExpr}
Export            ::=  ‘export’ ImportExpr {‘,’ ImportExpr}
ImportExpr        ::=  SimpleRef {‘.’ id} ‘.’ ImportSpec
ImportSpec        ::=  NamedSelector
                    |  WildcardSelector
                    | ‘{’ ImportSelectors) ‘}’
NamedSelector     ::=  id [‘as’ (id | ‘_’)]
WildCardSelector  ::=  ‘*' | ‘given’ [InfixType]
ImportSelectors   ::=  NamedSelector [‘,’ ImportSelectors]
                    |  WildCardSelector {‘,’ WildCardSelector}
```
