---
layout: default
title: "已删除：自动应用"
parent: 已删除的特性
grand_parent: 参考
nav_order: 13
---

# {{ page.title }}

以前在不提供参数调用零元方法时，一个空的参数列表 `()` 会被隐式插入。例如：

```scala
def next(): T = ...
next     // is expanded to next()
```

在 Scala 3 中，这个惯用法是错误的。

```scala
next
^
missing arguments for method next
```

在 Scala 3 中，应用语法必须完全遵循参数语法。在 Java 中定义的方法，
以及正在重写 Java 中定义的方法的方法是例外。对这种情况宽容的原因是，
如果没有例外，则所有人都要用这种写法

```scala
xs.toString().length()
```

替代

```scala
xs.toString.length
```

后者是符合 Scala 惯用法的，因为它符合统一访问原则。
这一原则指出，应该能够将对象成员从字段修改为无副作用的方法，
也能够再修改回来，而不影响访问该成员的客户端。
因此，Scala 鼓励定义没有 `()` 参数列表的“属性”方法，
而带有副作用的方法应该带有 `()` 参数列表。
在 Java 中定义的方法不能做出这种区分；对于它们来说，
`()` 总是必须的。因此 Scala 通过允许无参数引用在用户侧解决了这个问题。
But where Scala allows that freedom for all method references, Scala 3
restricts it to references of external methods that are not defined
themselves in Scala 3.

For reasons of backwards compatibility, Scala 3 for the moment also
auto-inserts `()` for nullary methods that are defined in Scala 2, or
that override a method defined in Scala 2. It turns out that, because
the correspondence between definition and call was not enforced in
Scala so far, there are quite a few method definitions in Scala 2
libraries that use `()` in an inconsistent way. For instance, we
find in `scala.math.Numeric`

```scala
def toInt(): Int
```

whereas `toInt` is written without parameters everywhere
else. Enforcing strict parameter correspondence for references to
such methods would project the inconsistencies to client code, which
is undesirable. So Scala 3 opts for more leniency when type-checking
references to such methods until most core libraries in Scala 2 have
been cleaned up.

Stricter conformance rules also apply to overriding of nullary
methods.  It is no longer allowed to override a parameterless method
by a nullary method or _vice versa_. Instead, both methods must agree
exactly in their parameter lists.

```scala
class A {
   def next(): Int
}

class B extends A {
   def next: Int // overriding error: incompatible type
}
```

Methods overriding Java or Scala 2 methods are again exempted from this
requirement.

### Migrating code

Existing Scala code with inconsistent parameters can still be compiled
in Scala 3 under `-source 3.0-migration`. When paired with the `-rewrite`
option, the code will be automatically rewritten to conform to Scala 3's
stricter checking.

### Reference

For more information, see [Issue #2570](https://github.com/lampepfl/dotty/issues/2570) and [PR #2716](https://github.com/lampepfl/dotty/pull/2716).
