---
layout: default
title: 语言版本
parent: 用法
nav_order: 5
---

# {{ page.title }}

Scala 3 编译器当前支持的默认 Scala 语言版本是 `3.0`。也可以指定其他语言版本：

 - `3.0-migration`：与 `3.0` 相同，但是具有 Scala 2 兼容模式，有助于将源码从 Scala 2.13 迁移到 Scala 3。主要区别是：
   - 将 Scala 3 中一些不允许的 Scala 2 构造标记为迁移警告，而不是硬错误，
   - 放宽一些规则以兼容 Scala 2.13，
   - 对 Scala 2.13 与 3.0 之间变化的语义给出一些额外警告，
   - 结合 `-rewrite` 提供从 Scala 2.13 到 3.0 的代码重写功能。

- `future`：预览 3.0 后下一个版本的更改。在这个文档页面中，我们将具有这些更改的版本称为 `3.1`，但其中一些更改可能会在之后的 `3.x` 版本中推出。
一些 Scala 2 中特定的的惯用法将在这个版本中删除。这个版本支持的特性集将随着接近发布时间而不断完善。

- `future-migration`：与 `future` 相同，但提供一些从 `3.0` 迁移的辅助功能。与 `3.0-migration` 下提供的辅助功能类似，
这些功能包括迁移警告和可选的重写功能。

有两种方式指定语言版本。

- 使用 `-source` 命令行参数设置，例如 `-source 3.0-migration`。
- 在编译单元顶部导入 `scala.language`，例如：

```scala
package p
import scala.language.`future-migration`

class C { ... }
```

语言导入将取代编译单元中的命令行参数设置。一个编译单元只允许一个语言导入，并且它必须位于该单元的任意定义之前。
