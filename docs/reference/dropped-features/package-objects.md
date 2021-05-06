---
layout: default
title: "已删除：包对象"
parent: 已删除的特性
grand_parent: 参考
nav_order: 7
---

# {{ page.title }}

包对象（Package Object）
```scala
package object p {
  val a = ...
  def b = ...
}
```
将被删除。它在 Scala 3.0 中依然可用，但之后会被弃用并删除。

包对象不再被需要，因为现在可以在顶层编写各类定义。例如：

```scala
package p
type Labelled[T] = (String, T)
val a: Labelled[Int] = ("count", 1)
def b = a._2

case class C()

extension (x: C) def pair(y: C) = (x, y)
```

包中可能有多个源文件包含各自的顶层定义，源文件可以自由的将顶层值、方法和类型定义与类和对象混合。

编译器会将以下类别的顶层定义包装到合成的对象中：

 - 所有模式、值、方法与类型定义，
 - 隐式类和对象，
 - 不透明类型别名的伴生对象。

如果源文件 `src.scala` 中包含了这样的顶层定义，他们会被放到名为 `src$package` 的顶层对象中。
当然，包装是透明的。`src` 中的定义仍然可以作为包含它的包的成员进行访问。

**注意：**这意味着

1. 包含顶层定义的源文件名称与二进制兼容性相关。如果名称变化，则生成的对象以及类的名称也会变化。

2. 顶层主方法 `def main(args: Array[String]): Unit = ...` 也会像其他方法一样被包装。
   如果它声明在源文件 `src.scala` 中，则在命令行内可以使用类似 `scala src$package` 这样的命令调用它。
   由于“程序名”是 mangled 的，所以建议 `main` 方法总是放在显式命名的对象中。

3. `private` 的解释方式与是否被包装无关。`private` 的顶层定义总是能在包裹它的包中的任何地方可见。

4. 如果多个顶层定义是具有相同名称的重载变体，则它们必须来自同一源文件。
