---
layout: default
title: 枚举和 ADT 的翻译
parent: 枚举
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

编译器将枚举和它的 case 扩展为值使用 Scala 其他语言特性的代码。因此，Scala 中的枚举是便捷的*语法糖*，
它们不是理解 Scala 核心所必需的。

现在我们详细解释枚举的扩展。首先，一些术语和惯用符号：

 - 我们使用 `E` 作为一个枚举的名称，使用 `C` 作为出现在 `E` 中的 case。
 - 我们使用 `<...>` 表示在某些情况下可能为空的语法结构。例如，`<value-params>` 表示一个或多个多个参数列表 `(...)`，或者什么都没有。

 - 枚举 case 分为三类：
   - *类 case* 是那些参数化的 case，可以带有一个类型参数部分 `[...]`，一个或多个参数部分 `(...)`。
   - *简单 case* 是非泛型枚举中既没有参数也没有 extends 子句或者类体的 case。也就是说，它们只包含一个名称。
   - *值 case* 是所有没有参数部分，但是有（可能是生成的）extends 子句或类体的 case。

  简单 case 和值 case 统称为*单例 case*。

脱糖规则表明类 case 会被映射到 case 类，单例 case 会被映射到 `val` 定义。

有九条脱糖规则。规则(1)脱糖枚举定义。规则(2)和(3)脱糖简单 case。规则(4)到(6)为缺少 `extends` 子句的 case 定义它们。
规则(7)到(9)定义了如何将带有 `extends` 子句的 case 映射到 `case class` 或者 `val`。

1. 一个 `enum` 定义
   ```scala
   enum E ... { <defs> <cases> }
   ```
   扩展为一个继承 `scala.reflect.Enum` trait 的 `sealed abstract` 
   类和与其关联的包含所有定义的 case 通过规则 (2-8) 展开后结果的伴生对象。
   枚举类以编译器生成的 import 开始，导入了所有 case 的名称 `<caseIds>`，
   以便在类中不使用前缀的情况下使用它们。
   ```scala
   sealed abstract class E ... extends <parents> with scala.reflect.Enum {
     import E.{ <caseIds> }
      <defs>
   }
   object E { <cases> }
   ```

2. 由 `,` 分隔的枚举名列表
   ```scala
   case C_1, ..., C_n
   ```
   扩展为
   ```scala
   case C_1; ...; case C_n
   ```
   原本的 case 上的所有 modifier 和注解都会延伸到所有扩展出的 case 上。

3. 枚举 `E` 中不接受类型参数的简单 case
   ```scala
   case C
   ```
   扩展为
   ```scala
   val C = $new(n, "C")
   ```
   这里 `$new` 是一个私有方法，用于创建 `E` 的实例（见下文）。

4. 如果 `E` 是一个接受类型参数
   ```scala
   V1 T1 >: L1 <: U1 ,   ... ,    Vn Tn >: Ln <: Un      (n > 0)
   ```
   的枚举，其中每个 variance `Vi` 是 `'+'` 或 `'-'`，则简单 case
   ```scala
   case C
   ```
   扩展为
   ```scala
   case C extends E[B1, ..., Bn]
   ```
   `Bi` 当 `Vi = '+'` 时为 `Li`，当 `Vi = '-'` 时为 `Ui`。然后使用规则(8)进一步重写该结果。
   枚举带有 non-variant 类型参数情况下的简单 case 是不允许的（但可以使用显式带有 `extends` 子句的值 case）。

5. 不接受类型参数的枚举 `E` 中没有 extends 子句的类 case 
   ```scala
   case C <type-params> <value-params>
   ```
   扩展为
   ```scala
   case C <type-params> <value-params> extends E
   ```
   然后使用规则(9)进一步重写该结果。
6. 如果 `E` 是一个接受类型参数(们) `Ts` 的枚举，则既没有类型参数也没有 extends 子句的类 case
   ```scala
   case C <value-params>
   ```
   扩展为
   ```scala
   case C[Ts] <value-params> extends E[Ts]
   ```
   然后使用规则(9)进一步重写该结果。本身带有类型参数的类 case 需要显式给出 extends 子句。

7. 如果 `E` 是一个接受类型参数(们) `Ts` 的枚举，则没有类型参数但带有 extends 子句的类 case
   ```scala
   case C <value-params> extends <parents>
   ```
   扩展为
   ```scala
   case C[Ts] <value-params> extends <parents>
   ```
   前提是类型参数(们) `Ts` 至少在 `<value-params>` 中的参数类型或 `<parents>` 的类型参数中提到至少一次。

8. 值 case
   ```scala
   case C extends <parents>
   ```
   扩展为 `E` 的伴生对象中的值定义
   ```scala
   val C = new <parents> { <body>; def ordinal = n }
   ```
   其中 `n` 是伴生对象中 case 从零开始的序号。这个匿名类还实现了从 `Enum` 中继承的抽象的 `Product` 方法。
   
   值 case 引用 `<parents>` 类型参数中封闭 `enum` 的类型参数是一个错误。

9. A class case
   ```scala
   case C <params> extends <parents>
   ```
   expands analogous to a final case class in `E`'s companion object:
   ```scala
   final case class C <params> extends <parents>
   ```
   The enum case defines an `ordinal` method of the form
   ```scala
   def ordinal = n
   ```
   where `n` is the ordinal number of the case in the companion object,
   starting from 0.

   It is an error if a value case refers to a type parameter of the enclosing `enum`
   in a parameter type in `<params>` or in a type argument of `<parents>`, unless that parameter is already
   a type parameter of the case, i.e. the parameter name is defined in `<params>`.

   The compiler-generated `apply` and `copy` methods of an enum case
   ```scala
   case C(ps) extends P1, ..., Pn
   ```
   are treated specially. A call `C(ts)` of the apply method is ascribed the underlying type
   `P1 & ... & Pn` (dropping any [transparent traits](../other-new-features/transparent-traits.md))
   as long as that type is still compatible with the expected type at the point of application.
   A call `t.copy(ts)` of `C`'s `copy` method is treated in the same way.

### Translation of Enums with Singleton Cases

An enum `E` (possibly generic) that defines one or more singleton cases
will define the following additional synthetic members in its companion object (where `E'` denotes `E` with
any type parameters replaced by wildcards):

   - A method `valueOf(name: String): E'`. It returns the singleton case value whose identifier is `name`.
   - A method `values` which returns an `Array[E']` of all singleton case
     values defined by `E`, in the order of their definitions.

If `E` contains at least one simple case, its companion object will define in addition:

   - A private method `$new` which defines a new simple case value with given
     ordinal number and name. This method can be thought as being defined as
     follows.

     ```scala
     private def $new(_$ordinal: Int, $name: String) =
        new E with runtime.EnumValue:
           def ordinal = _$ordinal
           override def productPrefix = $name // if not overridden in `E`
           override def toString = $name      // if not overridden in `E`
     ```

The anonymous class also implements the abstract `Product` methods that it inherits from `Enum`.
The `ordinal` method is only generated if the enum does not extend from `java.lang.Enum` (as Scala enums do not extend
`java.lang.Enum`s unless explicitly specified). In case it does, there is no need to generate `ordinal` as
`java.lang.Enum` defines it. Similarly there is no need to override `toString` as that is defined in terms of `name` in
`java.lang.Enum`. Finally, `productPrefix` will call `this.name` when `E` extends `java.lang.Enum`.

### Scopes for Enum Cases

A case in an `enum` is treated similarly to a secondary constructor. It can access neither the enclosing `enum` using `this`, nor its value parameters or instance members using simple
identifiers.

Even though translated enum cases are located in the enum's companion object, referencing
this object or its members via `this` or a simple identifier is also illegal. The compiler typechecks enum cases in the scope of the enclosing companion object but flags any such illegal accesses as errors.

### Translation of Java-compatible enums

A Java-compatible enum is an enum that extends `java.lang.Enum`. The translation rules are the same as above, with the reservations defined in this section.

It is a compile-time error for a Java-compatible enum to have class cases.

Cases such as `case C` expand to a `@static val` as opposed to a `val`. This allows them to be generated as static fields of the enum type, thus ensuring they are represented the same way as Java enums.

### Other Rules

- A normal case class which is not produced from an enum case is not allowed to extend
  `scala.reflect.Enum`. This ensures that the only cases of an enum are the ones that are
  explicitly declared in it.

- If an enum case has an `extends` clause, the enum class must be one of the
  classes that's extended.
