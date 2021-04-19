---
layout: default
title: 统一应用函数
parent: 其他新特性
grand_parent: 参考
nav_order: 3
---

# {{ page.title }}

Scala 为 case 类生成 apply 方法，因此可以简单地使用函数应用创建 case 类的实例，
而不需要写出 `new`。

Scala 3 将此方案推广到了所有具体类。例如：

```scala
class StringBuilder(s: String):
   def this() = this("")

StringBuilder("abc")  // old: new StringBuilder("abc")
StringBuilder()       // old: new StringBuilder()
```

这段代码能够运行是因为带有两个 `apply` 方法的伴生对象随着类一起生成。
这个伴生对象如下所示：

```scala
object StringBuilder:
   inline def apply(s: String): StringBuilder = new StringBuilder(s)
   inline def apply(): StringBuilder = new StringBuilder()
```

合成的对象 `StringBuilder` 以及 `apply` 被成为*构造器代理*。
构造器代理甚至为 Java 类以及来自 Scala 2 的类生成。具体规则如下：

 1. 构造器代理伴生对象 `object C` 为具体类 `C` 创建，前提是该类还没有伴生对象，
    并且在定义 `C` 的作用域内也没有定义或继承其他名为 `C` 的值或方法。

 2. 构造器代理 `apply` 方法为具体类 `C` 创建，前提是

    - 该类有一个伴生对象（可能由步骤 1 生成），并且
    - 该伴生对象还未定义名为 `apply` 的成员。

    每个生成的 `apply` 方法都转发给类的一个构造函数。它具有和构造函数相同的类型和值参数。

构造器代理伴生对象本身不能用作值。必须使用 `apply` 函数才能选择到代理伴生对象（或者直接应用参数，这种情况下 `apply` 被隐式插入）。

构造器代理也不允许对普通定义进行遮蔽。也就是说，如果一个标识符被解析为一个构造器代理，
并且同一个标识符也被定义或导入到另一个作用域中，则会报告一个歧义错误。

### 动机

省略 `new` 会隐藏实现细节，并使代码更易读。尽管它需要一个新的规则，但它也很可能会增加语言的规则性，
因为 case 类以及提供了函数调用创建语法（并常常是为此单独定义的）。
