# Parsing Notes

This document explains the parsing ideas used by ToyParser: recursive descent,
left recursion, precedence, associativity, and top-down versus bottom-up parsing.

## The Big Picture

A parser checks whether a stream of tokens matches the language grammar. If it
does, it usually produces an AST.

For example:

```js
let x = 1 + 2 * 3;
```

The tokenizer first produces tokens like:

```text
let IDENTIFIER = NUMBER + NUMBER * NUMBER ;
```

Then the parser turns those tokens into an AST shape like:

```text
VariableStatement
  VariableDeclaration x
    BinaryExpression +
      NumericLiteral 1
      BinaryExpression *
        NumericLiteral 2
        NumericLiteral 3
```

The important part is that `2 * 3` is grouped before `1 + ...` because `*` has
higher precedence than `+`.

## Recursive Descent

ToyParser uses a hand-written recursive descent parser.

Recursive descent means grammar rules are implemented as functions, and those
functions call other grammar-rule functions.

For example, the grammar says:

```bnf
Expression
  : AssignmentExpression
  ;
```

The Swift parser mirrors that:

```swift
func expressionBuilder() throws -> Expression {
  try assignmentExpressionBuilder()
}
```

A larger expression rule delegates to the next tighter precedence level:

```swift
func assignmentExpressionBuilder() throws -> Expression {
  var left = try logicalOrExpressionBuilder()
  ...
}
```

The expression parser descends through precedence levels:

```text
Expression
  -> AssignmentExpression
  -> LogicalOrExpression
  -> LogicalAndExpression
  -> EqualityExpression
  -> RelationalExpression
  -> AdditiveExpression
  -> MultiplicativeExpression
  -> UnaryExpression
  -> LeftHandSideExpression
  -> PrimaryExpression
```

This is why the parser is called recursive descent: it starts from a broad rule
and descends into smaller rules.

Array literals are primary expressions too:

```js
[x, y + 1, foo()]
```

Their elements are parsed with `LogicalOrExpression`, not
`AssignmentExpression`. This keeps value construction from accepting assignment
syntax inside array elements, so `[y = 2]` is rejected while expressions such as
`[y || z, x + 1]` remain valid.

Dictionary literals follow the same primary-expression model:

```js
{ "name": "Vela", count: 3 }
```

Both dictionary keys and values are parsed with `LogicalOrExpression`. This
keeps dictionary construction consistent with array construction: `{ y: z = 2 }`
is rejected, while `{ y: z || fallback, count: 1 + 2 }` remains valid. A leading
`{` at statement position still means `BlockStatement`; dictionary literals are
parsed in expression positions such as variable initializers and call arguments.

The OOP additions follow the same model. `statementBuilder()` routes `class` to
a class-declaration parser, while `primaryExpressionBuilder()` routes `this` and
`new` to expression parsers:

```swift
case .KEYWORD(keyword: "class"):
  return try .ClassDeclaration(classDeclarationStamentBuilder())

case .KEYWORD(keyword: "this"):
  return try thisExpressionBuilder()

case .KEYWORD(keyword: "new"):
  return try newExpressionBuilder()
```

So class declarations are statements, and `this` / `new` are value-producing
expressions.

## Precedence

Precedence controls which operators bind more tightly.

In normal arithmetic:

```js
1 + 2 * 3
```

means:

```text
1 + (2 * 3)
```

not:

```text
(1 + 2) * 3
```

ToyParser represents precedence with separate parser functions. Lower-precedence
functions call higher-precedence functions first.

For addition:

```swift
func additiveExpressionBuilder() throws -> Expression {
  try binaryExpressionBuilder([.ADD, .MINUS], operand: multiplicativeExpressionBuilder)
}
```

For multiplication:

```swift
func multiplicativeExpressionBuilder() throws -> Expression {
  try binaryExpressionBuilder([.MUL, .DIV], operand: unaryExpressionBuilder)
}
```

So when parsing:

```js
1 + 2 * 3
```

the additive parser sees the `+`, but it asks the multiplicative parser to parse
the right-hand side. The multiplicative parser consumes `2 * 3` as one unit.

That produces:

```text
1 + (2 * 3)
```

## Associativity

Associativity controls how operators at the same precedence level group.

Addition is usually left-associative:

```js
1 + 2 + 3
```

means:

```text
(1 + 2) + 3
```

Assignment is usually right-associative:

```js
x = y = 1
```

means:

```text
x = (y = 1)
```

ToyParser handles these two cases differently.

Left-associative binary operators are parsed with a loop:

```swift
func binaryExpressionBuilder(
  _ op: TokenType,
  operand: () throws -> Expression
) throws -> Expression {
  var left = try operand()

  while lookahead?.type == op {
    let operatorValue = try eat(op).value
    let right = try operand()
    left = .binaryExpression(
      BinaryExpression(
        operatorValue: operatorValue,
        left: left,
        right: right
      )
    )
  }

  return left
}
```

For:

```js
1 + 2 + 3
```

the loop builds:

```text
((1 + 2) + 3)
```

Assignment is parsed with right recursion:

```swift
return try .assignmentExpression(
  AssignmentExpression(
    operatorValue: operatorToken.value,
    left: left,
    right: assignmentExpressionBuilder()
  )
)
```

For:

```js
x = y = 1
```

that builds:

```text
x = (y = 1)
```

## Left Recursion

Left recursion is a grammar shape where a rule references itself as the first
thing on the right-hand side.

For example:

```bnf
AdditiveExpression
  : AdditiveExpression (ADD | MINUS) MultiplicativeExpression
  | MultiplicativeExpression
  ;
```

The recursive reference is on the left:

```text
AdditiveExpression -> AdditiveExpression ...
```

That grammar describes left-associative expressions like:

```js
1 + 2 + 3
```

But a recursive descent parser cannot implement that rule directly.

This direct implementation would never stop:

```swift
func additiveExpressionBuilder() throws -> Expression {
  let left = try additiveExpressionBuilder()
  let operatorValue = try eat(lookahead!.type).value
  let right = try multiplicativeExpressionBuilder()
  return .binaryExpression(
    BinaryExpression(
      operatorValue: operatorValue,
      left: left,
      right: right
    )
  )
}
```

The function calls itself before consuming any token. That causes infinite
recursion.

So recursive descent parsers usually rewrite this:

```bnf
AdditiveExpression
  : AdditiveExpression (ADD | MINUS) MultiplicativeExpression
  | MultiplicativeExpression
  ;
```

into this:

```bnf
AdditiveExpression
  : MultiplicativeExpression ((ADD | MINUS) MultiplicativeExpression)*
  ;
```

The Swift version is:

```swift
var left = try multiplicativeExpressionBuilder()

while let operatorType = lookahead?.type, [.ADD, .MINUS].contains(operatorType) {
  let operatorValue = try eat(operatorType).value
  let right = try multiplicativeExpressionBuilder()
  left = .binaryExpression(
    BinaryExpression(
      operatorValue: operatorValue,
      left: left,
      right: right
    )
  )
}

return left
```

So:

```text
left recursion = grammar form
left associativity = expression grouping
```

They are related, but they are not the same thing.

## Top-Down Parsing

ToyParser is a top-down parser.

Top-down parsing starts from the largest grammar rule and works down toward
tokens.

ToyParser starts with:

```bnf
Program
  : StatementList
  ;
```

Then it descends:

```text
Program
  -> StatementList
  -> Statement
  -> ExpressionStatement
  -> Expression
  -> AssignmentExpression
  -> ...
  -> PrimaryExpression
  -> NUMBER
```

That maps naturally to recursive descent functions:

```swift
func programBuilder() throws -> Program {
  try Program(body: statementListBuilder())
}
```

Then:

```swift
func statementBuilder() throws -> Statement {
  switch lookahead.type {
  case .KEYWORD(keyword: "let"):
    return try .Variable(variableStatementBuilder())
  default:
    return try .Expression(expressionStatementBuilder())
  }
}
```

The parser predicts what kind of construct it is looking at based on the current
token, then calls the function for that construct.

## Bottom-Up Parsing

A bottom-up parser works in the opposite direction. It starts with tokens and
reduces them into larger grammar rules.

For:

```js
1 + 2 * 3;
```

a bottom-up parser might reduce like this:

```text
NUMBER
  -> NumericLiteral
  -> PrimaryExpression
  -> UnaryExpression

2 * 3
  -> MultiplicativeExpression

1 + (2 * 3)
  -> AdditiveExpression
  -> Expression
  -> ExpressionStatement
  -> Statement
  -> Program
```

Bottom-up parsers are commonly generated by tools such as Yacc, Bison, or parser
generators that support LR/LALR parsing.

Eva's grammar uses `LALR1`, which is a bottom-up parser strategy.

## Top-Down vs Bottom-Up

Both parser families can parse real programming languages, but they have
different tradeoffs.

Top-down recursive descent:

- Easy to write by hand.
- Easy to debug.
- Maps cleanly to one function per grammar rule.
- Cannot directly handle left-recursive grammar.
- Often needs grammar rewriting for expression rules.

Bottom-up LR/LALR:

- Usually generated from a grammar file.
- Handles many left-recursive grammars naturally.
- Good for formal language grammars.
- Harder to debug by hand.
- Error messages often need extra work to make them friendly.

ToyParser uses:

```text
hand-written recursive descent
top-down parsing
precedence by one function per precedence level
left-associative operators by loops
right-associative assignment by recursion
```

## Where Syntax Checking Happens

Syntax checking happens while building the AST.

The key helper is:

```swift
func eat(_ tokenType: TokenType) throws -> Token
```

`eat` means: the grammar expects this token right now.

If the current token matches, the parser consumes it and moves to the next token.
If it does not match, parsing fails with a syntax error.

For example, a `while` statement expects:

```bnf
WhileStatement
  : WHILE LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ;
```

The parser implementation mirrors that:

```swift
try eat(.KEYWORD(keyword: "while"))
try eat(.LEFT_BRACE)
let condition = try expressionBuilder()
try eat(.RIGHT_BRACE)
let block = try blockStatementBuilder()
```

So this is valid syntax:

```js
while (i < 10) {
  i += 1;
}
```

But this is a syntax error:

```js
while (i < 10 {
  i += 1;
}
```

The parser expected `RIGHT_BRACE`, meaning `)`, before the block.

## Syntax vs Semantics

The parser checks syntax, not meaning.

This is syntactically valid:

```js
square(2);
```

The parser can produce:

```text
FuncCallExpression
  IdentifierExpression square
  Arguments
    NumericLiteral 2
```

But the parser does not know whether `square` exists.

That check belongs to semantic analysis, name resolution, type checking, or
runtime evaluation.

Likewise:

```js
getCallback()();
```

is valid syntax. The AST is a call whose callee is another call:

```text
FuncCallExpression
  FuncCallExpression
    IdentifierExpression getCallback
```

A later phase must check whether:

```text
getCallback exists
getCallback is callable
getCallback() returns something callable
```

That is not a parser responsibility.

The same split applies to OOP syntax. These are parser-valid forms:

```js
class Point extends Shape {
  def constructor(x, y) {
    this.x = x;
    this.y = y;
  }
}

let p = new Point(1, 2);
```

The parser checks only that those tokens match the grammar. Later semantic or
runtime phases must decide whether `Shape` exists, whether `Point` is
constructible, what `this` means in the current scope, and what object allocation
actually does.
