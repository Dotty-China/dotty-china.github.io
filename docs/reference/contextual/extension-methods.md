---
layout: default
title: 扩展方法
parent: 上下文抽象
grand_parent: 参考
nav_order: 6
---

# {{ page.title }}

扩展方法（Extension Method）允许在定义类型后向其添加方法。例如：

```scala
case class Circle(x: Double, y: Double, radius: Double)

extension (c: Circle)
   def circumference: Double = c.radius * math.Pi * 2
```

与常规方法一样，扩展方法也可以使用中缀 `.` 调用：

```scala
val circle = Circle(0, 0, 1)
circle.circumference
```

## 扩展方法的翻译

扩展方法被翻译为一个带有特殊标签的方法，该方法把前导参数部分作为其第一个参数列表。这里用 `<extension>` 表示的标签是编译器内部的。
因此，上述 `circumference` 定义会被翻译为以下方法，也可以像这样调用：

```scala
<extension> def circumference(c: Circle): Double = c.radius * math.Pi * 2

assert(circle.circumference == circumference(circle))
```

## 操作符

扩展方法语法也可以用于定义操作符。例如：

```scala
extension (x: String)
   def < (y: String): Boolean = ...
extension (x: Elem)
   def +: (xs: Seq[Elem]): Seq[Elem] = ...
extension (x: Number)
   infix def min (y: Number): Number = ...

"ab" < "c"
1 +: List(2, 3)
x min 3
```

以上三个定义被翻译为

```scala
<extension> def < (x: String)(y: String): Boolean = ...
<extension> def +: (xs: Seq[Elem])(x: Elem): Seq[Elem] = ...
<extension> infix def min(x: Number)(y: Number): Number = ...
```

注意，在把右关联操作符 `+:` 翻译为扩展方法时，会交换两个参数 `x` 和 `xs`。
这类似于把右绑定操作符实现为普通方法。Scala 编译器把中缀操作符 `x +: xs` 
预处理为 `xs.+:(x)`，因此扩展方法最终把这个序列作为第一个参数（in other words, the
two swaps cancel each other out）。详情[请参见这里](./right-associative-extension-methods.md)。

## 泛型扩展

也可以通过添加类型参数来扩展泛型类型。例如：

```scala
extension [T](xs: List[T])
   def second = xs.tail.head

extension [T: Numeric](x: T)
   def + (y: T): T = summon[Numeric[T]].plus(x, y)
```

`extension` 上的泛型参数也可以与方法本身上的类型参数组合使用：

```scala
extension [T](xs: List[T])
   def sumBy[U: Numeric](f: T => U): U = ...
```

与方法类型参数匹配的类型参数可以普通地传递：

```scala
List("a", "bb", "ccc").sumBy[Int](_.length)
```

相比之下，仅当方法作为非扩展方法使用时，才能传递与 `extension` 后的类型参数匹配的类型参数：

```scala
sumBy[String](List("a", "bb", "ccc"))(_.length)
```

或者，同时传递两个泛型参数：

```scala
sumBy[String](List("a", "bb", "ccc"))[Int](_.length)
```

扩展也可以接受 using 子句。例如，上面的 `+` 扩展也可以使用 using 子句等价的表示为：

```scala
extension [T](x: T)(using n: Numeric[T])
   def + (y: T): T = n.plus(x, y)
```

## 聚合扩展

有时需要定义几个共享同一左侧参数类型的扩展方法。这种情况下，可以把公共参数“拉出”到单个扩展中，
并把所有方法括在大括号或者缩进区域中。例如：

```scala
extension (ss: Seq[String])

   def longestStrings: Seq[String] =
      val maxLength = ss.map(_.length).max
      ss.filter(_.length == maxLength)

   def longestString: String = longestStrings.head
```

也可以使用大括号这样写（注意缩进区域仍可以在大括号内使用）：

```scala
extension (ss: Seq[String]) {

   def longestStrings: Seq[String] = {
      val maxLength = ss.map(_.length).max
      ss.filter(_.length == maxLength)
   }

  def longestString: String = longestStrings.head
}
```

注意 `longestString` 的右侧：它直接调用了 `longestStrings`，隐式的假设公共扩展值 `ss` 作为接收者。

这样的聚合扩展是单独扩展的简写，每个方法都是单独定义的。例如，上面的扩展会被展开为：

```scala
extension (ss: Seq[String])
   def longestStrings: Seq[String] =
      val maxLength = ss.map(_.length).max
      ss.filter(_.length == maxLength)

extension (ss: Seq[String])
   def longestString: String = ss.longestStrings.head
```

聚合扩展还可以接受类型参数，并可以具有 using 子句。例如：

```scala
extension [T](xs: List[T])(using Ordering[T])
   def smallest(n: Int): List[T] = xs.sorted.take(n)
   def smallestIndices(n: Int): List[Int] =
      val limit = smallest(n).max
      xs.zipWithIndex.collect { case (x, i) if x <= limit => i }
```

## 对扩展方法调用的翻译

要把一个引用转换为扩展方法，编译器需要了解扩展方法。在这种情况下，我们称扩展方法*适用于*这个引用点。
扩展方法有四种可能的适用方式：

 1. 扩展方法通过定义、继承或导入的方式，在引用的封闭作用域中简单名称可见。
 2. 扩展方法是引用点处某个可见的 given 实例的成员。
 3. 引用的形式是 `r.m`，并且扩展方法定义在 `r` 的类型的隐式作用域中。
 4. 引用的形式是 `r.m`，并且扩展方法定义在 `r` 的类型的隐式作用域中的某个 given 实例中。

这里是第一条规则的一个例子：

```scala
trait IntOps:
   extension (i: Int) def isZero: Boolean = i == 0

   extension (i: Int) def safeMod(x: Int): Option[Int] =
      // extension method defined in same scope IntOps
      if x.isZero then None
      else Some(i % x)

object IntOpsEx extends IntOps:
   extension (i: Int) def safeDiv(x: Int): Option[Int] =
      // extension method brought into scope via inheritance from IntOps
      if x.isZero then None
      else Some(i / x)

trait SafeDiv:
   import IntOpsEx.* // brings safeDiv and safeMod into scope

   extension (i: Int) def divide(d: Int): Option[(Int, Int)] =
      // extension methods imported and thus in scope
      (i.safeDiv(d), i.safeMod(d)) match
         case (Some(d), Some(r)) => Some((d, r))
         case _ => None
```

根据第二条规则，可以通过定义包含扩展方法的 given 实例来提供扩展方法，就像这样：

```scala
given ops1: IntOps with {}  // brings safeMod into scope

1.safeMod(2)
```

根据第三和第四条规则，如果扩展方法位于接收器类型的隐式作用域中，或位于该范围中的 given 实例内，
则扩展方法可用。例如：

```scala
class List[T]:
   ...
object List:
   ...
   extension [T](xs: List[List[T]])
      def flatten: List[T] = xs.foldLeft(List.empty[T])(_ ++ _)

   given [T: Ordering]: Ordering[List[T]] with
      extension (xs: List[T])
         def < (ys: List[T]): Boolean = ...
end List

// extension method available since it is in the implicit scope
// of List[List[Int]]
List(List(1, 2), List(3, 4)).flatten

// extension method available since it is in the given Ordering[List[T]],
// which is itself in the implicit scope of List[Int]
List(1, 2) < List(3)
```

将选择解析为扩展方法的精确规则如下。

假设有一个选择 `e.m[Ts]`，`m` 不是 `e` 的成员，类型参数 `[Ts]` 是可选的，并且 `T` 是预期类型。
按照顺序尝试以下两种重写：
 
 1. 选择被重写为 `m[Ts](e)`。
 2. 如果第一个重写没有使用预期类型 `T` 进行类型检查，并且某个符合条件的对象 `o` 中存在扩展方法 `m`，
    选择被重写为 `o.m[Ts](e)`。当 `o` 满足**以下条件之一**时，`o` 是*符合条件*的：
    
    - `o` 是 `T` 的隐式作用域的构成部分。
    - `o` 是应用点处可见的 given 实例。
    - `o` 是 `T` 隐式作用域中的 given 实例。

    第二种重写触发时，编译器也尝试从 `T` 隐式转换为包含 `m` 的类型。如果有多于一种重写方式，则会产生歧义错误结果。

扩展方法也可以在没有 preceding 表达式的情况下使用简单标识符引用。如果一个标识符 `g` 出现在扩展方法 `f` 的函数体中，
并且引用在同一个聚合扩展中的扩展方法 `g`

```scala
extension (x: T)
   def f ... = ... g ...
   def g ...
```

则标识符被重写为 `x.g`。如果 `f` 和 `g` 是同一个方法，也遵循这个规则。例如：

```scala
extension (s: String)
   def position(ch: Char, n: Int): Int =
      if n < s.length && s(n) != ch then position(ch, n + 1)
      else n
```

这种情况下，递归调用 `position(ch, n + 1)` 被展开为 `s.position(ch, n + 1)`。整个扩展方法被重写为

```scala
def position(s: String)(ch: Char, n: Int): Int =
   if n < s.length && s(n) != ch then position(s)(ch, n + 1)
   else n
```

## 语法

下面是扩展方法与聚合扩展相对于[当前语法](../syntax.md)的语法更改。

```ebnf
BlockStat         ::=  ... | Extension
TemplateStat      ::=  ... | Extension
TopStat           ::=  ... | Extension
Extension         ::=  ‘extension’ [DefTypeParamClause] ‘(’ DefParam ‘)’
                       {UsingParamClause} ExtMethods
ExtMethods        ::=  ExtMethod | [nl] <<< ExtMethod {semi ExtMethod} >>>
ExtMethod         ::=  {Annotation [nl]} {Modifier} ‘def’ DefDef
```

上述 production 规则中的记号 `<<< ts >>>` 定义如下：

```
<<< ts >>>        ::=  ‘{’ ts ‘}’ | indent ts outdent
```
`extension` 是一个软关键字。只有出现在语句开头，并且其后紧接 `[` 或 `(` 时才会被识别为关键字。
其他的情况下都会被视为标识符。
