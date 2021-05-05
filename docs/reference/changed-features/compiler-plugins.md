---
layout: default
title: 编译器插件的变化
parent: 其他变化的特性
grand_parent: 参考
nav_order: 16
---

# {{ page.title}}

从 Dotty 0.9 开始，Dotty（Scala 3）开始支持编译器插件。与 Scala 2 的 `scala` 相比，
这有两个显著的变化：

- 不支持 analyzer 插件
- 添加了对 research 插件的支持

`scalac` 中的[Analyzer 插件][1]在类型检查期间运行，可能会影响正常的类型检查。
这是一个非常强大的特性，但是对于生产用途，可预测的、一致的类型检查更为重要。

为了实验和研究，Scala 3 引入了 *research 插件*。Research 插件比 `scalac` 的 analyzer 插件更强大，
因为它允许插件作者定制整个编译器 pipeline。可以很容易用定制的 typer 替代标准的 typer，
或为 DSL 创建一个解析器。不过，research 插件只在 Scala 3 的 nightly 或 snaphot 版本中启用。

向编译器 pipeline 添加新的阶段的常见插件在 Scala 3 中被称为*标准插件（standard plugin）*。
特性上它们与 `scalac` 插件类似，但是 API 有一些小变化。

## 使用编译器插件

标准插件和 research 插件都可以通过为 `scalac` 添加 `-Xplugin:` 选项启用：

```shell
scalac -Xplugin:pluginA.jar -Xplugin:pluginB.jar Test.scala
```

编译器将检查所提供的 jar，在 jar 的根目录中查找名为 `plugin.properties` 的属性文件。
属性文件指定了插件类的完全限定类名。属性文件的格式如下：

```properties
pluginClass=dividezero.DivideZero
```

这与需要 `scalac-plugin.xml` 文件的 `scalac` 插件不同。

从 1.1.5 开始，`sbt` 支持 Scala 3 编译器插件。更多信息请参见 [`sbt` 文档][2]。

## 编写标准编译器插件

下面是一个简单的编译器插件的源码，该插件将整数除以零作为错误报告。
```scala
package dividezero

import dotty.tools.dotc.ast.Trees.*
import dotty.tools.dotc.ast.tpd
import dotty.tools.dotc.core.Constants.Constant
import dotty.tools.dotc.core.Contexts.Context
import dotty.tools.dotc.core.Decorators.*
import dotty.tools.dotc.core.StdNames.*
import dotty.tools.dotc.core.Symbols.*
import dotty.tools.dotc.plugins.{PluginPhase, StandardPlugin}
import dotty.tools.dotc.transform.{Pickler, Staging}

class DivideZero extends StandardPlugin {
   val name: String = "divideZero"
   override val description: String = "divide zero check"

   def init(options: List[String]): List[PluginPhase] =
      (new DivideZeroPhase) :: Nil
}

class DivideZeroPhase extends PluginPhase {
   import tpd.*

   val phaseName = "divideZero"

   override val runsAfter = Set(Pickler.name)
   override val runsBefore = Set(Staging.name)

   override def transformApply(tree: Apply)(implicit ctx: Context): Tree = {
      tree match {
         case Apply(Select(rcvr, nme.DIV), List(Literal(Constant(0))))
         if rcvr.tpe <:< defn.IntType =>
            report.error("dividing by zero", tree.pos)
         case _ =>
            ()
      }
      tree
   }
}
```

插件的主类（`DivideZero`）必须继承 trait `StandardPlugin`，并实现 `init` 方法，
该方法接受插件的选项作为参数，返回要插入编译器 pipeline 的 `PluginPhase` 列表。

我们的插件向 pipeline 插入了一个编译器阶段。编译器阶段必须继承 trait `PluginPhase`。
为了指定何时执行阶段，我们还需要指定约束 `runsBefore` 与 `runsAfter`，它们是阶段名称的列表。

我们现在可以通过覆盖像 `transformXXX` 这样的方法转换树。

## 编写 Research 编译器插件

这里是一个 research 插件的模板。

```scala
import dotty.tools.dotc.core.Contexts.Context
import dotty.tools.dotc.core.Phases.Phase
import dotty.tools.dotc.plugins.ResearchPlugin

class DummyResearchPlugin extends ResearchPlugin {
   val name: String = "dummy"
   override val description: String = "dummy research plugin"

   def init(options: List[String], phases: List[List[Phase]])(implicit ctx: Context): List[List[Phase]] =
      phases
}
```

A research plugin must extend the trait `ResearchPlugin`  and implement the
method `init` that takes the plugin's options as argument as well as the compiler
pipeline in the form of a list of compiler phases. The method can replace, remove
or add any phases to the pipeline and return the updated pipeline.


[1]: https://github.com/scala/scala/blob/2.13.x/src/compiler/scala/tools/nsc/typechecker/AnalyzerPlugins.scala
[2]: https://www.scala-sbt.org/1.x/docs/Compiler-Plugins.html
