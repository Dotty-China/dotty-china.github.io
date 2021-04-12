---
layout: default
title: API 文档
parent: scaladoc
nav_order: 1
---

# {{ page.title }}

Scaladoc 的主要功能是从代码注释创建 API 文档。

默认情况下，代码注释被理解为 Markdown，但我们也支持 Scaladoc 旧的 [Wiki 语法](https://docs.scala-lang.org/style/scaladoc.html)。

## 语法

### 定义链接（Definition link）

我们的定义链接语法与旧的 Scaladoc 语法非常接近，不过我们已经做了一些改进。

#### 基本语法

一个定义链接类似于：`[[scala.collection.immutable.List]]`。

也就是说，定义链接是由 `.` 分割的标识符序列。为了与旧的 Scaladoc 语法兼容，标识符序列也可以用 `#` 分割。

默认情况下，一个标识符 `id` 引用第一个（源代码中的顺序）名为 `id` 的实体。标识符可以以 `$` 结尾，这会迫使它
引用一个值（一个对象，一个值，或者一个 `given` ）；标识符也可以以 `!` 结尾，这迫使它引用
一个类型（一个类，一个类型别名或者一个类型成员）。

链接相对于当前的源码位置进行解析。也就是说，一个类的文档中链接相对于包含该类的实体（一个包、一个类或者一个对象）；
对于其他定义的文档与此类似。

链接中的特殊字符可以使用反斜杠转义，这让它们成为标识符的一部分。例如 ` [[scala.collection.immutable\.List]] `
引用包 `scala.collection` 中的一个名为 <code>&#96;immutable.List&#96;</code> 的类。

#### 新语法

我们扩展了 Scaladoc 的定义链接，使其在源代码中的编写和阅读更加愉快。扩展它的目的还在于让链接和 Scala 语法更紧密地
结合在一起。新功能包括：

1. `package` can be used as a prefix to reference the enclosing package
    Example:
    ```scala
    package utils
    class C {
      def foo = "foo".
    }
    /** See also [[package.C]]. */
    class D {
      def bar = "bar".
    }
    ```
    The `package` keyword helps make links to the enclosing package shorter
    and a bit more resistant to name refactorings.
1. `this` can be used as a prefix to reference the enclosing classlike
    Example:
    ```scala
    class C {
      def foo = "foo"
      /** This is not [[this.foo]], this is bar. */
      def bar = "bar"
    }
    ```
    Using a Scala keyword here helps make the links more familiar, as well as
    helps the links survive class name changes.
1. Backticks can be used to escape identifiers
    Example:
    ```scala
    def `([.abusive.])` = ???
    /** TODO: Figure out what [[`([.abusive.])`]] is. */
    def foo = `([.abusive.])`
    ```
    Previously (versions 2.x), Scaladoc required backslash-escaping to reference such identifiers. Now (3.x versions),
    Scaladoc allows using the familiar Scala backtick quotation.

#### Why keep the Wiki syntax for links?

There are a few reasons why we've kept the Wiki syntax for documentation links
instead of reusing the Markdown syntax. Those are:

1. Nameless links in Markdown are ugly: `[](definition)` vs `[[definition]]`
    By far, most links in documentation are nameless. It should be obvious how to
    write them.
2. Local member lookup collides with URL fragments: `[](#field)` vs `[[#field]]`
3. Overload resolution collides with MD syntax: `[](meth(Int))` vs `[[meth(Int)]]`
4. Now that we have a parser for the link syntax, we can allow spaces inside (in
    Scaladoc one needed to slash-escape those), but that doesn't get recognized
    as a link in Markdown: `[](meth(Int, Float))` vs `[[meth(Int, Float)]]`

None of these make it completely impossible to use the standard Markdown link
syntax, but they make it much more awkward and ugly than it needs to be. On top
of that, Markdown link syntax doesn't even save any characters.
