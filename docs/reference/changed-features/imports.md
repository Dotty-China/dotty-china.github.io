---
layout: default
title: 导入
parent: 其他变化的特性
grand_parent: 参考
nav_order: 5
---

# {{ page.title }}

通配符和重命名导入（以及导出）的语法已修改。

## 通配符导入

通配符导入现在使用 `*` 而不是下划线表示。例如：

```scala
import scala.annotation.*  // imports everything in the annotation package
```

如果要导入名为 `*` 的成员，可以在使用反引号括起其名称。

```scala
object A:
   def * = ...
   def min = ...

object B:
  import A.`*`   // imports just `*`

object C:
  import A.*     // imports everything in A
```

## 重命名导入

To rename or exclude an import, we now use `as` instead of `=>`. A single renaming import no longer needs to be enclosed in braces. Examples:

```scala
import A.{min as minimum, `*` as multiply}
import Predef.{augmentString as _, *}     // imports everything except augmentString
import scala.annotation as ann
import java as j
```

## 迁移

为了支持 cross-building，Scala 3 除了支持新的导入语法外，也支持旧式导入语法（`_` 作为通配符，`=>` 表示重命名）。
旧式语法将在未来被删除。选项 `-source 3.1-migration -rewrite` 下提供了从旧式语法到新式语法的自动重写。

## 语法

```
Import            ::=  ‘import’ ImportExpr {‘,’ ImportExpr}
ImportExpr        ::=  SimpleRef {‘.’ id} ‘.’ ImportSpec
ImportSpec        ::=  NamedSelector
                    |  WildcardSelector
                    | ‘{’ ImportSelectors) ‘}’
NamedSelector     ::=  id [‘as’ (id | ‘_’)]
WildCardSelector  ::=  ‘*' | ‘given’ [InfixType]
ImportSelectors   ::=  NamedSelector [‘,’ ImportSelectors]
                    |  WildCardSelector {‘,’ WildCardSelector}
```
