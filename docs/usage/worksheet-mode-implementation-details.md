---
layout: default
title: Worksheet 模式 - 实现细节
nav_exclude: true
---

简而言之，Worksheet 扩展了 Language Server Protocol 并依赖 Scala 3 REPL 执行代码。

## 执行

Worksheet 中的每个表达式和语句都被提取并传递给 Scala 3 REPL。REPL 完成对一个输入单元的求值后，
它将发送一个特殊的分隔符指示该输入的输出结束。（请查看 `dotty.tools.languageserver.worksheet.InputStreamConsumer`）

这个过程将持续进行，直到所有输入都被执行。

Scala 3 REPL 在单独的 JVM 中运行。执行器（`dotty.tools.languageserver.worksheet.Evaluator`）
在项目配置无变化时重用 JVM 进程。

## 与客户端通信

Worksheet 扩展了 Language Server Protocol，添加了一个 request 和一个 notification。

### 执行 Worksheet 请求

Worksheet 执行请求从客户端发送到服务器，请求服务器执行给定的 Worksheet 并流式处理结果。

*Request:*

 - 方法：`worksheet/run`
 - 参数：`WorksheetRunParams`，定义如下：
   ```typescript
   interface WorksheetRunParams {
       /**
        * The worksheet to evaluate.
        */
       textDocument: VersionedTextDocumentIdentifier;
   }
   ```

*Response:*

 - 结果：`WorksheetRunResult`，定义如下：
   ```typescript
   interface WorksheetRunResult {
       /**
        * Indicates whether evaluation was successful.
        */
       success: boolean;
   }
   ```

### Worksheet 输出通知

Worksheet 输出通知从服务器服务器发送到客户端，以指示 Worksheet 执行产生了一些输出。

*Notification:*

 - 方法：`worksheet/publishOutput`
 - 参数：`WorksheetRunOutput`，定义如下：
   ```typescript
   interface WorksheetRunOutput {
       /**
        * The worksheet that produced this output.
        */
       textDocument: VersionedTextDocumentIdentifier;

       /**
        * The range of the expression that produced this output.
        */
       range: Range;

       /**
        * The output that has been produced.
        */
       content: string;
   }
   ```
