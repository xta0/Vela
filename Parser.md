# Grammar Rules

This document describes the parser as it exists in the codebase now. The parser
is a hand-written recursive descent parser. Each `*Builder()` function parses one
grammar rule and returns either a concrete AST node or an enum wrapper that holds
one.

## Parser Overview

Parsing starts in `Parser.parse(_:)`.

1. The tokenizer is initialized with the source string.
2. `lookahead` is set to the first token from `tokenizer.getNextToken()`.
3. `programBuilder()` parses the whole program.
4. Each builder consumes expected tokens with `eat(_:)`.
5. `eat(_:)` validates the current `lookahead`, returns that token, and advances
   `lookahead` to the next token.
6. If a builder sees an unexpected token, it throws a parser error.

The parser is "lookahead driven": most decisions are based on the current token.
For example, `statementBuilder()` checks `lookahead` to decide whether the next
statement is empty, block, variable, if, or expression.

## Tokenizer Overview

The tokenizer is lazy. It produces one token each time the parser asks for one.

`Token.specs` order matters. The first matching regex wins. This is why more
specific operators must appear before more general operators:

```text
&&, || before identifiers or unknown handling
==, != before =
+=, -=, *=, /= before +, -, *, /
```

Whitespace and comments are skipped by the tokenizer. They do not appear in the
parser.

Current operator token groups:

```text
RELATIONAL:  < <= > >=
EQUALITY:    == !=
LOGICAL_AND: &&
LOGICAL_OR:  ||
ASSIGNMENT:  = += -= *= /=
ADD:         + -
MUL:         * /
UNARY:       !
```

Token order matters for unary and equality: `!=` must be checked before `!`.
Otherwise `!=` would be split as `!` plus `=`.

Current keyword tokens:

```text
let
if
else
true
false
null
while
for
do
def
return
class
extends
super
new
this
```

Keyword regexes require a trailing word boundary, so an identifier like
`returnValue` stays one identifier token instead of being split into `return`
plus `Value`.

## AST Node Model

Concrete AST payloads conform to `ASTNode`. Wrapper enums choose between
variants.

Concrete statement AST nodes:

```text
Program
EmptyStatement
BlockStatement
ExpressionStatement
VariableStatement
IFStatement
WhileIterationStatement
ForIterationStatement
FunctionDeclarationStatement
ReturnStatement
ClassDeclarationStatement
VariableDeclaration
```

Expression AST nodes:

```text
NumericLiteral
StringLiteral
BooleanLiteral
NullLiteral
IdentifierExpression
BinaryExpression
LogicalExpression
UnaryExpression
AssignmentExpression
MemberExpression
FuncCallExpression
ThisExpression
SuperExpression
NewExpression
```

`Statement` is not a concrete AST node. It is an enum wrapper around concrete
statement nodes:

```text
Statement.Empty(EmptyStatement)
Statement.Block(BlockStatement)
Statement.Expression(ExpressionStatement)
Statement.Variable(VariableStatement)
Statement.If(IFStatement)
Statement.Iteration(IterationStatement)
Statement.Function(FunctionDeclarationStatement)
Statement.Return(ReturnStatement)
Statement.ClassDeclaration(ClassDeclarationStatement)
```

`Expression` is also an enum wrapper, but it currently conforms to `ASTNode`
because expressions are value-producing AST nodes in this parser.

## Program And Statements

Program parsing starts here:

```text
Program
  : StatementList
  ;
```

`programBuilder()` delegates to `statementListBuilder()`.

### StatementList

```text
StatementList
  : Statement
  | StatementList Statement
  ;
```

The BNF is left-recursive, but the implementation uses a loop:

```text
parse one Statement
while lookahead exists and is not the stop token:
  parse another Statement
```

This is important because recursive descent parsers cannot directly implement
left recursion. A direct `StatementList -> StatementList Statement` call would
call itself forever before consuming anything.

`statementListBuilder(stopTokenType:)` is used in two modes:

```text
program body: no stop token, parse until EOF
block body: stop at RIGHT_CURLY_BRACE
```

### Statement

```text
Statement
  : EmptyStatement
  | BlockStatement
  | ExpressionStatement
  | VariableStatement
  | IfStatement
  | IterationStatement
  | FunctionDeclaration
  | ReturnStatement
  | ClassDeclaration
  ;
```

`statementBuilder()` chooses the concrete statement from `lookahead`:

```text
;                 -> EmptyStatement
{                 -> BlockStatement
let               -> VariableStatement
if                -> IfStatement
while / do / for  -> IterationStatement
def               -> FunctionDeclaration
return            -> ReturnStatement
class             -> ClassDeclaration
default           -> ExpressionStatement
```

### EmptyStatement

```text
EmptyStatement
  : SEMICOLON
  ;
```

Example:

```text
;
```

Produces:

```text
EmptyStatement
```

### BlockStatement

```text
BlockStatement
  : LEFT_CURLY_BRACE StatementList? RIGHT_CURLY_BRACE
  ;
```

Examples:

```text
{}
{ 1; let x = 2; }
```

A block owns a list of statements. It uses `statementListBuilder(stopTokenType:
.RIGHT_CURLY_BRACE)` so parsing stops before the closing `}`.

### ExpressionStatement

```text
ExpressionStatement
  : Expression SEMICOLON
  ;
```

Examples:

```text
1 + 2;
x = 3;
a && b;
```

Expression statements are the fallback statement kind. If the parser does not
see a token that starts one of the known statement forms, it assumes the
statement starts with an expression.

### VariableStatement

```text
VariableStatement
  : KEYWORD("let") VariableDeclarationList SEMICOLON
  ;
```

Examples:

```text
let x;
let x = 1;
let x = 1, y = 2;
```

Variable declarations are parsed as:

```text
VariableDeclarationList
  : VariableDeclaration
  | VariableDeclarationList COMMA VariableDeclaration
  ;

VariableDeclaration
  : Identifier VariableInitializer?
  ;

VariableInitializer
  : SIMPLE_ASSIGNMENT AssignmentExpression
  ;
```

The implementation parses declaration lists with a loop over commas. Initializer
expressions delegate to `assignmentExpressionBuilder()`, so an initializer can
contain any expression level:

```text
let y = x && z;
let x = a == b < c;
let total = 1 + 2 * 3;
```

### IfStatement

```text
IfStatement
  : KEYWORD("if") LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  | KEYWORD("if") LEFT_BRACE Expression RIGHT_BRACE BlockStatement KEYWORD("else") BlockStatement
  ;
```

Examples:

```text
if (x) {}
if (x) { y; } else { z; }
```

The current parser requires both `ifBody` and `elseBody` to be block statements.
The condition is parsed with `expressionBuilder()`, so it supports the full
expression grammar.

### IterationStatement

```text
IterationStatement
  : WhileStatement
  | DoWhileStatement
  | ForStatement
  ;
```

Examples:

```text
while (x) {}
do {} while (x);
for (let i = 0; i < 10; i = i + 1) {}
```

`iterationStatementBuilder()` routes by keyword. All loop bodies are currently
parsed as block statements.

### WhileStatement

```text
WhileStatement
  : KEYWORD("while") LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ;
```

Examples:

```text
while (x) {}
while (x < 10) { x = x + 1; }
```

The condition delegates to `expressionBuilder()`, so it supports the full
expression grammar.

### DoWhileStatement

```text
DoWhileStatement
  : KEYWORD("do") BlockStatement KEYWORD("while") LEFT_BRACE Expression RIGHT_BRACE SEMICOLON
  ;
```

Examples:

```text
do {} while (x);
do { x = x + 1; } while (x < 10);
```

The current AST stores `do while` in the same `WhileIterationStatement` payload
as `while`. That is enough for parsing the condition and body, but an
interpreter may eventually need a distinct do-while node because `do while`
executes the body before checking the condition.

### ForStatement

```text
ForStatement
  : KEYWORD("for") LEFT_BRACE ForStatementInit? SEMICOLON Expression? SEMICOLON Expression? RIGHT_BRACE BlockStatement
  ;

ForStatementInit
  : VariableStatementInit
  | Expression
  ;
```

Examples:

```text
for (;;) {}
for (let i = 0; i < 10; i = i + 1) {}
for (i = 0; i < 10; i = i + 1) {}
for (; i < 10; i = i + 1) {}
```

The initializer is separate from the condition and update because it may be
either a variable declaration or an expression. The condition and update are
ordinary expressions.

### FunctionDeclaration

```text
FunctionDeclaration
  : KEYWORD("def") Identifier LEFT_BRACE FormalParameterList? RIGHT_BRACE BlockStatement
  ;

FormalParameterList
  : Identifier
  | FormalParameterList COMMA Identifier
  ;
```

Examples:

```text
def noop() {}
def add(x, y) { return x + y; }
```

Function declarations are statements. The parser records the function name,
parameter names, and block body. Function calls are parsed as expressions by the
left-hand-side expression layer.

### ReturnStatement

```text
ReturnStatement
  : KEYWORD("return") Expression? SEMICOLON
  ;
```

Examples:

```text
return;
return x + 1;
```

### ClassDeclaration

```text
ClassDeclaration
  : KEYWORD("class") Identifier ClassExtends? BlockStatement
  ;

ClassExtends
  : KEYWORD("extends") Identifier
  ;
```

Examples:

```text
class Point {}
class Point extends Shape {}
class Point { def constructor(x, y) { this.x = x; this.y = y; } }
```

Class declarations are statements. The parser records the class identifier,
optional superclass expression, and block body. The class body is parsed as a
regular block statement, so function declarations and other statements inside a
class use the same statement parser as top-level code.

The parser allows a return statement wherever statements are allowed. Whether
`return` is only valid inside a function is a later semantic/interpreter check,
not a syntax check in the current parser.

## Expression Delegation And Precedence

Expression parsing starts at the lowest-precedence expression and delegates
downward to tighter expressions.

Current chain, lowest to highest:

```text
Expression
AssignmentExpression
LogicalOrExpression
LogicalAndExpression
EqualityExpression
RelationalExpression
AdditiveExpression
MultiplicativeExpression
UnaryExpression
LeftHandSideExpression
MemberExpression
PrimaryExpression
```

The key idea:

```text
Each level first parses the next tighter level.
If the current level's operator is present, it consumes that operator and parses
the right side.
If the operator is not present, it returns the tighter expression unchanged.
```

This fallback behavior is why a simple expression like `1 + 2` can start at
`assignmentExpressionBuilder()`. Assignment sees no assignment operator and
returns the result from lower levels.

### Expression

```text
Expression
  : AssignmentExpression
  ;
```

`expressionBuilder()` delegates to `assignmentExpressionBuilder()`.

### AssignmentExpression

```text
AssignmentExpression
  : LogicalOrExpression
  | LeftHandSideExpression AssignmentOperator AssignmentExpression
  ;

AssignmentOperator
  : SIMPLE_ASSIGNMENT
  | COMPLEX_ASSIGNMENT
  ;
```

Assignment delegates to logical OR for its fallback.

Assignment is right-associative because the right side recursively calls
`assignmentExpressionBuilder()`:

```text
x = y = 1
```

Parses as:

```text
x = (y = 1)
```

Assignment also validates the left side. Currently identifiers and member
expressions are valid assignment targets:

```text
x = 1                  valid
x += 1                 valid
object.property = 1    valid
object[property] = 1   valid
x + y = 1              invalid
```

### LogicalOrExpression

```text
LogicalOrExpression
  : LogicalAndExpression
  | LogicalOrExpression LOGICAL_OR LogicalAndExpression
  ;
```

Logical OR uses `||` and delegates to logical AND. This makes `||` looser than
`&&`.

Example:

```text
a || b && c
```

Parses as:

```text
a || (b && c)
```

Implementation note: the code uses a loop in `logicalExpressionBuilder`, so the
implemented associativity is left-associative:

```text
a || b || c
```

Parses as:

```text
(a || b) || c
```

### LogicalAndExpression

```text
LogicalAndExpression
  : EqualityExpression
  | LogicalAndExpression LOGICAL_AND EqualityExpression
  ;
```

Logical AND uses `&&` and delegates to equality. This makes `&&` tighter than
`||`, but looser than `==` and `!=`.

Example:

```text
a && b == c
```

Parses as:

```text
a && (b == c)
```

Like logical OR, the implementation is left-associative:

```text
a && b && c
```

Parses as:

```text
(a && b) && c
```

### EqualityExpression

```text
EqualityExpression
  : RelationalExpression
  | EqualityExpression EQUALITY RelationalExpression
  ;
```

Equality uses `==` and `!=`. It delegates to relational, so relational binds
tighter.

Example:

```text
a == b < c
```

Parses as:

```text
a == (b < c)
```

Equality is left-associative in the implementation:

```text
a == b != c
```

Parses as:

```text
(a == b) != c
```

### RelationalExpression

```text
RelationalExpression
  : AdditiveExpression
  | RelationalExpression RELATIONAL AdditiveExpression
  ;
```

Relational uses `<`, `<=`, `>`, and `>=`. It delegates to additive, so additive
binds tighter.

Example:

```text
x + 5 > 10
```

Parses as:

```text
(x + 5) > 10
```

Another example:

```text
a < b + 1
```

Parses as:

```text
a < (b + 1)
```

### AdditiveExpression

```text
AdditiveExpression
  : MultiplicativeExpression
  | AdditiveExpression ADD MultiplicativeExpression
  ;
```

Additive uses `+` and `-`. It delegates to multiplicative, so `*` and `/` bind
tighter than `+` and `-`.

Example:

```text
1 + 2 * 3
```

Parses as:

```text
1 + (2 * 3)
```

Additive is left-associative:

```text
1 + 2 - 3
```

Parses as:

```text
(1 + 2) - 3
```

### MultiplicativeExpression

```text
MultiplicativeExpression
  : UnaryExpression
  | MultiplicativeExpression MUL UnaryExpression
  ;
```

Multiplicative uses `*` and `/`. It delegates to unary, so unary binds tighter
than multiplication and division.

Example:

```text
8 / 4 * 2
```

Parses as:

```text
(8 / 4) * 2
```

Unary binds tighter than multiplication:

```text
!x * y
```

Parses as:

```text
(!x) * y
```

### UnaryExpression

```text
UnaryExpression
  : LeftHandSideExpression
  | UNARY UnaryExpression
  ;
```

Unary currently supports logical not, `!`.

Unary sits between multiplicative and left-hand-side expressions:

```text
MultiplicativeExpression
UnaryExpression
LeftHandSideExpression
```

That makes `!` tighter than `*`, `+`, relational, equality, and logical
operators. `UnaryExpression` is right-recursive because the operand of a unary
operator can itself be another unary expression.

Examples:

```text
!x && y     -> (!x) && y
!x == y     -> (!x) == y
!x * y      -> (!x) * y
!(x && y)   -> !(x && y)
!!x         -> !(!x)
```

`UnaryExpression` stores an `argument` because the AST needs to know what the
operator applies to. For `!x`, the operator is `!` and the argument is
`IdentifierExpression x`. For `!!x`, the outer `!` has another
`UnaryExpression` as its argument.

Current unsupported unary/update forms:

```text
++x
--x
+x
-x
```

Those need separate tokenizer and parser support before they should be accepted.

### LeftHandSideExpression

```text
LeftHandSideExpression
  : CallMemberExpression
  ;
```

Left-hand-side expressions are the expression forms that can appear on the left
of an assignment. The current implementation delegates to call/member parsing,
then assignment validation accepts identifiers and member expressions as valid
assignment targets.

### CallMemberExpression

```text
CallMemberExpression
  : MemberExpression
  | CallExpression
  ;

CallExpression
  : Callee Arguments
  ;

Callee
  : MemberExpression
  | CallExpression
  ;

Arguments
  : LEFT_BRACE ArgumentList? RIGHT_BRACE
  ;

ArgumentList
  : AssignmentExpression
  | ArgumentList COMMA AssignmentExpression
  ;
```

Examples:

```text
foo()
foo(x, y + 2)
object.method()
foo()()
super(x, y)
```

Call expressions store a callee expression and a list of argument expressions.
Arguments delegate to `assignmentExpressionBuilder()`, so calls can receive
plain expressions or assignment expressions.

### MemberExpression

```text
MemberExpression
  : PrimaryExpression
  | MemberExpression '.' Identifier
  | MemberExpression '[' Expression ']'
  ;
```

Member expressions parse property access and computed property access. They are
implemented with a loop, so chained member access builds from left to right.

Examples:

```text
object.property
object[property]
object.property[index]
this.x
this["x"]
```

Dot access stores `computed` as `false`, and bracket access stores `computed` as
`true`. The bracket form calls back into `expressionBuilder()`, so the property
can be any expression:

```text
object[index + 1]
```

### PrimaryExpression

```text
PrimaryExpression
  : Literal
  | ParenthesizedExpression
  | Identifier
  | ThisExpression
  | NewExpression
  ;
```

Primary provides the base values for member expressions. It parses values that
do not need a lower-level operator decision.

Examples:

```text
42
"hello"
true
false
null
x
(1 + 2)
this
new Point(1, 2)
new MyNameSpace.Point()
```

Parentheses call back into `expressionBuilder()`:

```text
ParenthesizedExpression
  : LEFT_BRACE Expression RIGHT_BRACE
  ;
```

That means a parenthesized expression can contain the full expression grammar:

```text
(x = a || b)
(1 + 2) * 3
```

`this` produces a `ThisExpression`. `new` produces a `NewExpression` with a
member-expression callee and argument list:

```text
NewExpression
  : KEYWORD("new") MemberExpression Arguments
  ;
```

### Literal

```text
Literal
  : NumericLiteral
  | StringLiteral
  | BooleanLiteral
  | NullLiteral
  ;
```

Literal builders:

```text
NumericLiteral  -> NUMBER
StringLiteral   -> STRING
BooleanLiteral  -> "true" | "false"
NullLiteral     -> "null"
```

## Delegation Summary

Statement delegation:

```text
parse
└─ programBuilder
   └─ statementListBuilder
      └─ statementBuilder
         ├─ emptyStatementBuilder
         ├─ blockStatementBuilder
         │  └─ statementListBuilder(stopTokenType: RIGHT_CURLY_BRACE)
         ├─ variableStatementBuilder
         │  └─ variableDeclarationListBuilder
         │     └─ variableDeclarationBuilder
         │        └─ variableInitializerBuilder
         │           └─ assignmentExpressionBuilder
         ├─ ifStatementBuilder
         │  ├─ expressionBuilder
         │  ├─ blockStatementBuilder
         │  └─ blockStatementBuilder optional else
         ├─ iterationStatementBuilder
         │  ├─ whileStatement
         │  │  ├─ expressionBuilder
         │  │  └─ blockStatementBuilder
         │  ├─ doWhileStatement
         │  │  ├─ blockStatementBuilder
         │  │  └─ expressionBuilder
         │  └─ forStatement
         │     ├─ forStatementInit optional
         │     │  ├─ variableStatementInitBuilder
         │     │  └─ expressionBuilder
         │     ├─ expressionBuilder optional condition
         │     ├─ expressionBuilder optional update
         │     └─ blockStatementBuilder
         ├─ functionDeclarationBuilder
         │  ├─ identifierBuilder
         │  ├─ formalParameterListBuilder optional
         │  └─ blockStatementBuilder
         ├─ returnStatementBuilder
         │  └─ expressionBuilder optional
         └─ expressionStatementBuilder
            └─ expressionBuilder
```

Expression delegation:

```text
expressionBuilder
└─ assignmentExpressionBuilder
   └─ logicalOrExpressionBuilder
      └─ logicalAndExpressionBuilder
         └─ equalityExpressionBuilder
            └─ relationalExpressionBuilder
               └─ additiveExpressionBuilder
                  └─ multiplicativeExpressionBuilder
                     └─ unaryExpressionBuilder
                        └─ leftHandSideExpressionBuilder
                           └─ memberExpressionBuilder
                              └─ primaryExpressionBuilder
                                 ├─ literalBuilder
                                 ├─ parenthesizedExpressionBuilder
                                 │  └─ expressionBuilder
                                 └─ identifierBuilder
```

## Associativity Summary

Current left-associative levels implemented with loops:

```text
LogicalOrExpression      ||
LogicalAndExpression     &&
EqualityExpression       == !=
RelationalExpression     < <= > >=
AdditiveExpression       + -
MultiplicativeExpression * /
MemberExpression         . []
StatementList
VariableDeclarationList
FormalParameterList
```

Current right-associative level:

```text
AssignmentExpression     = += -= *= /=
UnaryExpression          !
```

Assignment is right-associative because its right side calls
`assignmentExpressionBuilder()` again.

Unary is right-associative because its argument calls
`unaryExpressionBuilder()` again.

## Worked Examples

### `let y = x && z;`

```text
Program
StatementList
VariableStatement
VariableDeclaration y
VariableInitializer
AssignmentExpression
LogicalOrExpression
LogicalAndExpression
```

The initializer parses `x && z` as:

```text
LogicalExpression (&&)
├─ IdentifierExpression x
└─ IdentifierExpression z
```

### `x = a == b < c;`

Assignment is lowest, equality is below relational, and relational is below
additive:

```text
x = (a == (b < c))
```

### `object.property[index]`

Member expressions chain left to right:

```text
MemberExpression (computed)
├─ MemberExpression (property)
│  ├─ IdentifierExpression object
│  └─ IdentifierExpression property
└─ IdentifierExpression index
```

### `a || b && c == d`

Logical OR is looser than logical AND, and logical AND is looser than equality:

```text
a || (b && (c == d))
```

### `(1 + 2) * 3`

Parentheses call back into the full expression parser:

```text
(1 + 2) * 3
```

Parses as:

```text
(1 + 2) * 3
```

Without parentheses:

```text
1 + 2 * 3
```

Parses as:

```text
1 + (2 * 3)
```

### `!x * y`

Multiplicative delegates to unary, so `!x` is parsed before `* y` is attached:

```text
(!x) * y
```

### `!(x && y)`

Unary consumes `!`, then parses another unary expression as its argument.
Parentheses make the argument call back into the full expression parser:

```text
!(x && y)
```

The AST shape is:

```text
UnaryExpression (!)
└─ LogicalExpression (&&)
   ├─ IdentifierExpression x
   └─ IdentifierExpression y
```

## Current Known Gaps

Unary `!` is implemented. Prefix update operators and numeric unary operators
are not implemented yet:

```text
++x
--x
+x
-x
```

If those are added later, decide whether they are plain unary operators or a
separate update-expression level before changing the precedence chain.

Function and class declarations are parsed, and function/new/super call
expressions are parsed. The language still does not have scope binding, type
checking, object allocation semantics, or return execution semantics.
