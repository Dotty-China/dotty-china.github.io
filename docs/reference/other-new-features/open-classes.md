---
layout: default
title: 开放类
parent: 其他新特性
grand_parent: 参考
nav_order: 6
---

# {{ page.title }}

类上的 `open` 修饰符表示该类设计上可能被继承。例如：

```scala
// File Writer.scala
package p

open class Writer[T] {

   /** Sends to stdout, can be overridden */
   def send(x: T) = println(x)

   /** Sends all arguments using `send` */
   def sendAll(xs: T*) = xs.foreach(send)
}

// File EncryptedWriter.scala
package p

class EncryptedWriter[T: Encryptable] extends Writer[T] {
   override def send(x: T) = super.send(encrypt(x))
}
```

开放类通常附带一些文档，文档描述了类的方法间的内部调用模式以及可以重写的 hook。
我们称之为类的*扩展合约（Extension Contract）*。这不同于类与其用户的*外部合约（External Contract）*。

非开放的类仍然可以被继承，但至少满足以下条件之一：

 - 子类与被继承的类位于同一源文件中。这种情况下，继承通常是内部实现问题。

 - 已为子类启用语言特性 `adhocExtensions`。这通常使用子类源文件中的 `import` 子句启用：
   
   ```scala
   import scala.language.adhocExtensions
   ```

   或者也可以使用编译器参数 `-language:adhocExtensions` 启用这个特性。
   如果未启用该特性，则编译器将发出“feature”警告。例如，如果删除掉类 `Writer` 上的 `open` 修饰符，
   则编译 `EncryptedWriter` 时将产生警告：

   ```
   -- Feature Warning: EncryptedWriter.scala:6:14 ----
     |class EncryptedWriter[T: Encryptable] extends Writer[T]
     |                                              ^
     |Unless class Writer is declared 'open', its extension
     | in a separate file should be enabled
     |by adding the import clause 'import scala.language.adhocExtensions'
     |or by setting the compiler option -language:adhocExtensions.
   ```

## 动机

在编译类的时候，由三种可能的可扩展性预期：

1. 该类设计上允许被扩展。这意味着我们可以预期有一个为类精心制定和记录的扩展合约。

2. 对该类的扩展时被禁止的，例如为了保证正确性或安全性。

3. 没有明确的决定是哪种方式。这个类并不是为被扩展设计的，but if others find it useful to extend on an _ad-hoc_ basis, 
   let them go ahead. However, they are on their own in this case. There is no documented extension contract, and future versions of the class might break the extensions (by rearranging internal call patterns, for instance)。

这种三种情况被清晰的区分，使用 `open` 表示 (1)，使用 `final` 表示 (2)，没有修饰符表示 (3).

在 code base 中避免 _ad-hoc_ 扩展是一种好的做法，因为它们往往会导致系统难以演化且脆弱。
但某些情况下，这些扩展仍然是有用的：例如在测试中模拟类，或者使用临时补丁来添加特性或者修复库中类的错误。
这就是为什么允许 _ad-hoc_ 扩展，但需要显式启用语言特性。

## 细节

 - `open` 是一个软修饰符。除非位于修饰符位，否则它被视为普通标识符。
 - `open` 类不能是 `final` 或 `sealed` 的。
 - Trait 和 `abstract` 类总是 `open` 的，所以 `open` 修饰符对于它们是多余的。

## 与 `sealed` 的关系

既不是 `abstract` 也不是 `open` 的类类似于 `sealed` 类：它依然可以被扩展，
但只能在同一编译单元中扩展。不同之处在于在另一个编译单元中扩展它时的行为。
对于 `sealed` 类，这是一个错误，而对于普通的非开放类这依然允许，只是在 
`adhocExtensions` 特性未启用时会发出一条警告。

## 迁移

`open` 是 Scala 3 中的一个新修饰符。为了允许在 Scala 2.13 和 Scala 3.0 之间交叉编译而不发出警告，
对 ad-hoc 扩展的警告只在 `-source future` 下发出。发出警告将在 Scala 3.1 中成为默认行为。
