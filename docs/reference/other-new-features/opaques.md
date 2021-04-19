---
layout: default
title: 不透明类型别名
parent: 其他新特性
grand_parent: 参考
nav_order: 5
---

# {{ page.title }}

不透明类型别名提供了零开销类型抽象。例如：

```scala
object MyMath:

   opaque type Logarithm = Double

   object Logarithm:

      // These are the two ways to lift to the Logarithm type

      def apply(d: Double): Logarithm = math.log(d)

      def safe(d: Double): Option[Logarithm] =
         if d > 0.0 then Some(math.log(d)) else None

   end Logarithm

   // Extension methods define opaque types' public APIs
   extension (x: Logarithm)
      def toDouble: Double = math.exp(x)
      def + (y: Logarithm): Logarithm = Logarithm(math.exp(x) + math.exp(y))
      def * (y: Logarithm): Logarithm = x + y

end MyMath
```

这引入了 `Logarithm` 作为一种新的抽象类型，它被实现为 `Double`。
`Logarithm` 与 `Double` 相同的事实仅在定义 `Logarithm` 的作用域中才知道，
在上面的示例中该作用域为对象 `MyMath` 内部。换句话说，在作用域内它被视为类型别名，
但在外界这是不透明的，因此 `Logarithm` 被视为抽象类型，与 `Double` 无关。

`Logarithm` 的公共 API 由定义在伴生对象中的 `apply` 和 `safe` 方法组成。
它们把值从 `Double` 转换到 `Logarithm`。此外，`toDouble` 操作符以另一种方式进行转换，
以及操作符 `+` 和 `*` 被定义为 `Logarithm` 值的扩展方法。
以下操作将是有效的，因为它们使用 `MyMath` 对象中实现的功能。

```scala
import MyMath.Logarithm

val l = Logarithm(1.0)
val l2 = Logarithm(2.0)
val l3 = l * l2
val l4 = l + l2
```

但以下操作将导致类型错误：

```scala
val d: Double = l       // error: found: Logarithm, required: Double
val l2: Logarithm = 1.0 // error: found: Double, required: Logarithm
l * 2                   // error: found: Int(2), required: Logarithm
l / l2                  // error: `/` is not a member of Logarithm
```

## 不透明类型别名的界定

不透明类型别名也可以带有界定。例如：

```scala
object Access:

   opaque type Permissions = Int
   opaque type PermissionChoice = Int
   opaque type Permission <: Permissions & PermissionChoice = Int

   extension (x: Permissions)
      def & (y: Permissions): Permissions = x | y
   extension (x: PermissionChoice)
      def | (y: PermissionChoice): PermissionChoice = x | y
   extension (granted: Permissions)
      def is(required: Permissions) = (granted & required) == required
   extension (granted: Permissions)
      def isOneOf(required: PermissionChoice) = (granted & required) != 0

   val NoPermission: Permission = 0
   val Read: Permission = 1
   val Write: Permission = 2
   val ReadWrite: Permissions = Read | Write
   val ReadOrWrite: PermissionChoice = Read | Write

end Access
```

`Access` 对象定义了三个不透明类型别名：

- `Permission`，表示单个权限。
- `Permissions`，表示一组权限，含义是“授予其中所有权限”。
- `PermissionChoice`，表示一组权限，含义是“至少授予其中之一权限”。

在 `Access` 对象外，`Permissions` 类型的值可以使用 `&` 操作符组合，
其中 `x & y` 表示“授予 `x` *和* `y` 中的权限”。
`PermissionChoice` 类型的值可使用 `|` 操作符组合，
其中 `x | y` 表示“授予 `x` *或* `y` 中的权限”。

注意，在 `Access` 对象内部，`&` 和 `|` 操作符总是被解析为 `Int` 的相应方法，
因为成员方法总是优先于扩展方法。因此 `Access` 中的 `|` 扩展方法不会导致无限递归。
此外，`ReadWrite` 的定义必须使用 `|`，即使在 `Access` 外部的等效定义使用 `&`。

三个不透明类型别名都具有相同的基础表示类型 `Int`。`Permission` 类型具有上限 `Permissions & PermissionChoice`。
这使得在 `Access` 对象外部知道 `Permission` 是另外两个类型的子类型。
因此下面的使用场景能通过类型检查。

```scala
object User:
   import Access.*

   case class Item(rights: Permissions)

   val roItem = Item(Read)  // OK, since Permission <: Permissions
   val rwItem = Item(ReadWrite)
   val noItem = Item(NoPermission)

   assert(!roItem.rights.is(ReadWrite))
   assert(roItem.rights.isOneOf(ReadOrWrite))

   assert(rwItem.rights.is(ReadWrite))
   assert(rwItem.rights.isOneOf(ReadOrWrite))

   assert(!noItem.rights.is(ReadWrite))
   assert(!noItem.rights.isOneOf(ReadOrWrite))
end User
```

另一方面，调用 `roItem.rights.isOneOf(ReadWrite)` 会产生一个类型错误，
因为在 `Access` 外，`Permissions` 和 `PermissionChoice` 是不同的、不相关的类型。


## 类的不透明类型成员

通常不透明类型与对象一起使用，目的是隐藏模块的实现细节，但它也可以和类一起使用。

例如，我们可以把上面示例中的 `Logarithms` 重新定义为一个类：

```scala
class Logarithms:

   opaque type Logarithm = Double

   def apply(d: Double): Logarithm = math.log(d)

   def safe(d: Double): Option[Logarithm] =
      if d > 0.0 then Some(math.log(d)) else None

   def mul(x: Logarithm, y: Logarithm) = x + y
```

不同实例的不透明类型成员被视为不同的：

```scala
val l1 = new Logarithms
val l2 = new Logarithms
val x = l1(1.5)
val y = l1(2.6)
val z = l2(3.1)
l1.mul(x, y) // type checks
l1.mul(x, z) // error: found l2.Logarithm, required l1.Logarithm
```
一般来说，可以认为不透明类型仅在 `private[this]` 作用域内是透明的。

[更多细节](opaques-details.md){: .btn .btn-purple }
