---
layout: default
title: 可选括号
parent: 其他新特性
grand_parent: 参考
nav_order: 13
---

# {{ page.title }}

Scala 3 强制实施了一些规则，并允许让一些地方的括号 `{...}` 是可选的：

- 首先，一些缩进糟糕的程序被标记为警告。
- 其次，`{...}` 在一些地方是可选的。通常规则是添加一对可选的大括号不会改变缩进良好的程序的含义。

Scala 3 enforces some rules on indentation and allows some occurrences of braces `{...}` to be optional:

可以使用编译器 flag `-no-indent` 关闭这些变化。

## 缩进规则

编译器对缩进良好的程序强制执行两个规则，对违规处标为警告。

 1. 在用大括号分隔的区域中，不允许任何语句从左括号后新行中第一个语句的左侧开始。
    
    这个规则有助于查找缺失的右括号。它可以防止类似下面的错误：

    ```scala
    if (x < 0) {
      println(1)
      println(2)

    println("done")  // error: indented too far to the left
    ```
 2. 如果关闭了 significant indentation（也就是在 Scala 2 模式或 `-no-indent` 下），
    并且我们位于表达式缩进子部分的开头，并且缩进部分以换行结束，则下一条语句必须以小于子部分的缩进宽度开始。
    这可以防止因为忘记左大括号出现错误，如

    ```scala
    if (x < 0)
      println(1)
      println(2)   // error: missing `{`
    ```

这些规则仍为程序的缩进留下了很大余地。例如，它们不对表达式中的缩进施加任何限制，也不要求缩进块中的所有语句完全对齐。

这些规则通常有助于查明与缺少左或右大括号相关的错误的根本原因。这些错误通常很难诊断，尤其是在大型程序中。

## 可选括号

编译器将在某些换行符处插入 `<indent>` 或 `<outdent>` 标记。语法上成对的 `<indent>` 和 `<outdent>` 
标记与成对的大括号 `{` 和 `}` 有相同的效果。

该算法使用了 `IW` 栈存储前面代码缩进宽度。栈开始包含一个缩进宽度为零的元素。
*当前缩进宽度*是栈顶的缩进宽度。

有两条规则：

 1. 满足这些条件时，`<indent>` 被插入至换行符处：
 
     - 缩进区域可以从源中的当前位置开始。
     - 下一行的第一个 token 的缩进宽度严格大于当前缩进宽度。
   
    一个缩进区域可以从这些地方开始：
     
     - `extension` 的前导参数后。
     - `with` 中的 given instance 后。
     - “在行末的 : ” token 后（见下文）
     - 在下面的 token 之一后：

       ```
       =  =>  ?=>  <-  catch  do  else  finally  for
       if  match  return  then  throw  try  while  yield
       ```

    如果插入了一个 `<indent>`，则该 token 下一行的缩进宽度被 push 到 `IW` 上，使其成为新的当前缩进宽度。

 2. 满足这些条件时，`<outdent>` 被插入至换行符处：

    - 下一行的第一个 token 的缩进宽度严格小于当前缩进宽度。
    - 上一行的最后一个 token 不是以下表示上一语句继续的标记之一：
      ```
      then  else  do  catch  finally  yield  match
      ```
    - 如果下一行的第一个 token 是一个 [leading infix operator](../changed-features/operators.md)，
      则其缩进宽度小于当前缩进宽度，并且它要么匹配之前的缩进宽度，要么也小于封闭的缩进宽度。

    如果插入了一个 `<outdent>`，则弹出 `IW` 的顶部元素。如果下一行缩进宽度仍然小于新的当前缩进宽度，则重复步骤(2)。
    因此，可以在一行中插入多个 `<outdent>`。

    下面两个附加规则支持使用 ad-hoc layout 解析遗留代码。在未来的语言版本中，它们可能会被移除。

     - An `<outdent>` is also inserted if the next token following a statement sequence starting with an `<indent>` closes an indentation region, i.e. is one of `then`, `else`, `do`, `catch`, `finally`, `yield`, `}`, `)`, `]` or `case`.
     - An `<outdent>` is finally inserted in front of a comma that follows a statement sequence starting with an `<indent>` if the indented region is itself enclosed in parentheses.

It is an error if the indentation width of the token following an `<outdent>` does not match the indentation of some previous line in the enclosing indentation region. For instance, the following would be rejected.

```scala
if x < 0 then
     -x
  else   // error: `else` does not align correctly
     x
```

Indentation tokens are only inserted in regions where newline statement separators are also inferred:
at the top-level, inside braces `{...}`, but not inside parentheses `(...)`, patterns or types.

**Note:** The rules for leading infix operators above are there to make sure that
```scala
  one
  + two.match
      case 1 => b
      case 2 => c
  + three
```
is parsed as `one + (two.match ...) + three`. Also, that
```scala
if x then
    a
  + b
  + c
else d
```
is parsed as `if x then a + b + c else d`.

## Optional Braces Around Template Bodies

The Scala grammar uses the term _template body_ for the definitions of a class, trait, or object that are normally enclosed in braces. The braces around a template body can also be omitted by means of the following rule.

If at the point where a template body can start there is a `:` that occurs at the end
of a line, and that is followed by at least one indented statement, the recognized
token is changed from ":" to ": at end of line". The latter token is one of the tokens
that can start an indentation region. The Scala grammar is changed so an optional ": at end of line" is allowed in front of a template body.

Analogous rules apply for enum bodies and local packages containing nested definitions.

With these new rules, the following constructs are all valid:

```scala
trait A:
   def f: Int

class C(x: Int) extends A:
   def f = x

object O:
   def f = 3

enum Color:
   case Red, Green, Blue

new A:
   def f = 3

package p:
   def a = 1

package q:
   def b = 2
```

In each case, the `:` at the end of line can be replaced without change of meaning by a pair of braces that enclose the following indented definition(s).

The syntax changes allowing this are as follows:

```
Template    ::=  InheritClauses [colonEol] [TemplateBody]
EnumDef     ::=  id ClassConstr InheritClauses [colonEol] EnumBody
Packaging   ::=  ‘package’ QualId [nl | colonEol] ‘{’ TopStatSeq ‘}’
SimpleExpr  ::=  ‘new’ ConstrApp {‘with’ ConstrApp} [[colonEol] TemplateBody]
```

Here, `colonEol` stands for ": at end of line", as described above.
The lexical analyzer is modified so that a `:` at the end of a line
is reported as `colonEol` if the parser is at a point where a `colonEol` is
valid as next token.

## Spaces vs Tabs

Indentation prefixes can consist of spaces and/or tabs. Indentation widths are the indentation prefixes themselves, ordered by the string prefix relation. So, so for instance "2 tabs, followed by 4 spaces" is strictly less than "2 tabs, followed by 5 spaces", but "2 tabs, followed by 4 spaces" is incomparable to "6 tabs" or to "4 spaces, followed by 2 tabs". It is an error if the indentation width of some line is incomparable with the indentation width of the region that's current at that point. To avoid such errors, it is a good idea not to mix spaces and tabs in the same source file.

## Indentation and Braces

Indentation can be mixed freely with braces `{...}`, as well as brackets `[...]` and parentheses `(...)`. For interpreting indentation inside such regions, the following rules apply.

 1. The assumed indentation width of a multiline region enclosed in braces is the
    indentation width of the first token that starts a new line after the opening brace.

 2. The assumed indentation width of a multiline region inside brackets or parentheses is:

     - if the opening bracket or parenthesis is at the end of a line, the indentation width of token following it,
     - otherwise, the indentation width of the enclosing region.

 3. On encountering a closing brace `}`, bracket `]` or parenthesis `)`, as many `<outdent>` tokens as necessary are inserted to close all open nested indentation regions.

For instance, consider:
```scala
{
   val x = f(x: Int, y =>
      x * (
         y + 1
      ) +
      (x +
      x)
   )
}
```
 - Here, the indentation width of the region enclosed by the braces is 3 (i.e. the indentation width of the
statement starting with `val`).
 - The indentation width of the region in parentheses that follows `f` is also 3, since the opening
   parenthesis is not at the end of a line.
 - The indentation width of the region in parentheses around `y + 1` is 9
   (i.e. the indentation width of `y + 1`).
 - Finally, the indentation width of the last region in parentheses starting with `(x` is 6 (i.e. the indentation width of the indented region following the `=>`.

## Special Treatment of Case Clauses

The indentation rules for `match` expressions and `catch` clauses are refined as follows:

- An indentation region is opened after a `match` or `catch` also if the following `case`
  appears at the indentation width that's current for the `match` itself.
- In that case, the indentation region closes at the first token at that
  same indentation width that is not a `case`, or at any token with a smaller
  indentation width, whichever comes first.

The rules allow to write `match` expressions where cases are not indented themselves, as in the example below:

```scala
x match
case 1 => print("I")
case 2 => print("II")
case 3 => print("III")
case 4 => print("IV")
case 5 => print("V")

println(".")
```

## The End Marker

Indentation-based syntax has many advantages over other conventions. But one possible problem is that it makes it hard to discern when a large indentation region ends, since there is no specific token that delineates the end. Braces are not much better since a brace by itself also contains no information about what region is closed.

To solve this problem, Scala 3 offers an optional `end` marker. Example:

```scala
def largeMethod(...) =
   ...
   if ... then ...
   else
      ... // a large block
   end if
   ... // more code
end largeMethod
```

An `end` marker consists of the identifier `end` and a follow-on specifier token that together constitute all the tokes of a line. Possible specifier tokens are
identifiers or one of the following keywords

```scala
if   while    for    match    try    new    this    val   given
```

End markers are allowed in statement sequences. The specifier token `s` of an end marker must correspond to the statement that precedes it. This means:

- If the statement defines a member `x` then `s` must be the same identifier `x`.
- If the statement defines a constructor then `s` must be `this`.
- If the statement defines an anonymous given, then `s` must be `given`.
- If the statement defines an anonymous extension, then `s` must be `extension`.
- If the statement defines an anonymous class, then `s` must be `new`.
- If the statement is a `val` definition binding a pattern, then `s` must be `val`.
- If the statement is a package clause that refers to package `p`, then `s` must be the same identifier `p`.
- If the statement is an `if`, `while`, `for`, `try`, or `match` statement, then `s` must be that same token.

For instance, the following end markers are all legal:

```scala
package p1.p2:

   abstract class C():

      def this(x: Int) =
         this()
         if x > 0 then
            val a :: b =
               x :: Nil
            end val
            var y =
               x
            end y
            while y > 0 do
               println(y)
               y -= 1
            end while
            try
               x match
                  case 0 => println("0")
                  case _ =>
               end match
            finally
               println("done")
            end try
         end if
      end this

      def f: String
   end C

   object C:
      given C =
         new C:
            def f = "!"
            end f
         end new
      end given
   end C

   extension (x: C)
      def ff: String = x.f ++ x.f
   end extension

end p2
```

## When to Use End Markers

It is recommended that `end` markers are used for code where the extent of an indentation region is not immediately apparent "at a glance". People will have different preferences what this means, but one can nevertheless give some guidelines that stem from experience. An end marker makes sense if

- the construct contains blank lines, or
- the construct is long, say 15-20 lines or more,
- the construct ends heavily indented, say 4 indentation levels or more.

If none of these criteria apply, it's often better to not use an end marker since the code will be just as clear and more concise. If there are several ending regions that satisfy one of the criteria above, we usually need an end marker only for the outermost closed region. So cascades of end markers as in the example above are usually better avoided.

## Syntax

```
EndMarker         ::=  ‘end’ EndMarkerTag    -- when followed by EOL
EndMarkerTag      ::=  id | ‘if’ | ‘while’ | ‘for’ | ‘match’ | ‘try’
                    |  ‘new’ | ‘this’ | ‘given’ | ‘extension’ | ‘val’
BlockStat         ::=  ... | EndMarker
TemplateStat      ::=  ... | EndMarker
TopStat           ::=  ... | EndMarker
```

## Example

Here is a (somewhat meta-circular) example of code using indentation. It provides a concrete representation of indentation widths as defined above together with efficient operations for constructing and comparing indentation widths.

```scala
enum IndentWidth:
   case Run(ch: Char, n: Int)
   case Conc(l: IndentWidth, r: Run)

   def <= (that: IndentWidth): Boolean = this match
      case Run(ch1, n1) =>
         that match
            case Run(ch2, n2) => n1 <= n2 && (ch1 == ch2 || n1 == 0)
            case Conc(l, r)   => this <= l
      case Conc(l1, r1) =>
         that match
            case Conc(l2, r2) => l1 == l2 && r1 <= r2
            case _            => false

   def < (that: IndentWidth): Boolean =
      this <= that && !(that <= this)

   override def toString: String =
      this match
      case Run(ch, n) =>
         val kind = ch match
            case ' '  => "space"
            case '\t' => "tab"
            case _    => s"'$ch'-character"
         val suffix = if n == 1 then "" else "s"
         s"$n $kind$suffix"
      case Conc(l, r) =>
         s"$l, $r"

object IndentWidth:
   private inline val MaxCached = 40

   private val spaces = IArray.tabulate(MaxCached + 1)(new Run(' ', _))
   private val tabs = IArray.tabulate(MaxCached + 1)(new Run('\t', _))

   def Run(ch: Char, n: Int): Run =
      if n <= MaxCached && ch == ' ' then
         spaces(n)
      else if n <= MaxCached && ch == '\t' then
         tabs(n)
      else
         new Run(ch, n)
   end Run

   val Zero = Run(' ', 0)
end IndentWidth
```

## Settings and Rewrites

Significant indentation is enabled by default. It can be turned off by giving any of the options `-no-indent`, `old-syntax` and `language:Scala2`. If indentation is turned off, it is nevertheless checked that indentation conforms to the logical program structure as defined by braces. If that is not the case, the compiler issues a warning.

The Scala 3 compiler can rewrite source code to indented code and back.
When invoked with options `-rewrite -indent` it will rewrite braces to
indented regions where possible. When invoked with options `-rewrite -no-indent` it will rewrite in the reverse direction, inserting braces for indentation regions.
The `-indent` option only works on [new-style syntax](./control-syntax.md). So to go from old-style syntax to new-style indented code one has to invoke the compiler twice, first with options `-rewrite -new-syntax`, then again with options
`-rewrite -indent`. To go in the opposite direction, from indented code to old-style syntax, it's `-rewrite -no-indent`, followed by `-rewrite -old-syntax`.

## Variant: Indentation Marker `:`

Generally, the possible indentation regions coincide with those regions where braces `{...}` are also legal, no matter whether the braces enclose an expression or a set of definitions. There is one exception, though: Arguments to function can be enclosed in braces but they cannot be simply indented instead. Making indentation always significant for function arguments would be too restrictive and fragile.

To allow such arguments to be written without braces, a variant of the indentation scheme is implemented under language import
```scala
import language.experimental.fewerBraces
```
This variant is more contentious and less stable than the rest of the significant indentation scheme. In this variant, a colon `:` at the end of a line is also one of the possible tokens that opens an indentation region. Examples:

```scala
times(10):
   println("ah")
   println("ha")
```

or

```scala
xs.map:
   x =>
      val y = x - 1
      y * y
```

The colon is usable not only for lambdas and by-name parameters, but
also even for ordinary parameters:

```scala
credentials ++ :
   val file = Path.userHome / ".credentials"
   if file.exists
   then Seq(Credentials(file))
   else Seq()
```

How does this syntax variant work? Colons at the end of lines are their own token, distinct from normal `:`.
The Scala grammar is changed so that colons at end of lines are accepted at all points
where an opening brace enclosing an argument is legal. Special provisions are taken so that method result types can still use a colon on the end of a line, followed by the actual type on the next.
