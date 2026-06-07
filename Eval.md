# Interpreter Rules

This document describes how Vela evaluates the AST produced by the parser. The
implementation is a tree-walking interpreter written in Swift. Runtime behavior
lives under `Vela/Vela/Eval`.

## Evaluation Overview

Evaluation starts in `Eval.eval(_:)`.

1. `Eval.eval(_ program:)` uses `Eval.globalEnv`.
2. `Eval.eval(_ program:in:)` walks `program.body` in source order.
3. Each statement is dispatched through `Eval.execute(_:in:)`.
4. Expression statements and expression-containing statements call
   `Eval.evaluateExpression(_:in:)`.
5. The result of the last executed top-level statement is the program result.

The SwiftUI app displays that result in the right editor. Primitive values use
their normal `displayValue`; arrays and objects use `editorDisplayValue`, which
renders structured values as pretty JSON for inspection.

## Runtime Values

`EvalRuntimeValue` is the value model produced by the interpreter:

```text
int
double
string
bool
null
function
nativeFunction
object
array
klass
```

Objects are represented by `EvalRuntimeObject`. Plain dictionary literals are
objects with no class. Class instances are objects with a linked
`EvalRuntimeClass`.

Arrays are represented by `EvalRuntimeArray` and are mutable. Functions capture
their lexical environment in `EvalRuntimeFunction.closure`.

## Environments

`EvalEnvironment` stores variable bindings and points to an optional parent.

- The root environment installs native builtins.
- Block statements create child environments.
- Function calls create call environments under the function closure.
- For loops create loop-local environments.
- Assignment searches outward through parent environments.
- Undefined lookup or assignment throws `undefinedVariable`.

`Eval.globalEnv.clear()` removes user values and child scopes, then reinstalls
builtins.

## Program

```text
Program
  : StatementList
  ;
```

`Eval.eval` executes each statement in order and returns the last statement
result. An empty program would leave the result as `null`.

## Statement List

```text
StatementList
  : Statement
  | StatementList Statement
  ;
```

There is no separate runtime node for the statement list. The evaluator loops
over the `[Statement]` stored in `Program.body` or `BlockStatement.body`.

## Statements

```text
Statement
  : EmptyStatement
  | BlockStatement
  | VariableStatement
  | IfStatement
  | IterationStatement
  | FunctionDeclaration
  | ReturnStatement
  | BreakStatement
  | ContinueStatement
  | ClassDeclaration
  | ExpressionStatement
  ;
```

`Eval.execute(_:in:)` dispatches by `Statement` case.

### EmptyStatement

```text
EmptyStatement
  : SEMICOLON
  ;
```

Returns `null`.

### BlockStatement

```text
BlockStatement
  : LEFT_CURLY_BRACE StatementListOpt RIGHT_CURLY_BRACE
  ;
```

Creates a child environment under the current environment, executes each nested
statement in order, and returns the last nested statement result. Empty blocks
return `null`.

Control-flow signals from `return`, `break`, and `continue` propagate out of the
block until a function or loop handles them.

### ExpressionStatement

```text
ExpressionStatement
  : Expression SEMICOLON
  ;
```

Evaluates the expression and returns its value. This is why a final expression
such as `summary;` becomes the program result.

### VariableStatement

```text
VariableStatement
  : LET VariableDeclarationList SEMICOLON
  ;

VariableDeclaration
  : IDENTIFIER VariableInitializerOpt
  ;
```

Each declaration is evaluated left to right. A declaration with an initializer
stores the initializer result; a declaration without an initializer stores
`null`. The statement itself returns `null`.

### IfStatement

```text
IfStatement
  : IF LEFT_BRACE Expression RIGHT_BRACE BlockStatement ElseStatementOpt
  ;
```

The condition is evaluated and converted through `isTruthy`.

- Truthy condition: execute the `if` block.
- Falsy condition with `else`: execute the `else` block.
- Falsy condition without `else`: return `null`.

The executed block result becomes the if-statement result.

### WhileStatement

```text
WhileStatement
  : WHILE LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ;
```

Before each iteration, the condition is evaluated and converted through
`isTruthy`. The body result from the last completed iteration is returned. If no
iteration completes, the result is `null`.

`break` exits the loop. `continue` skips to the next condition check.

### DoWhileStatement

```text
DoWhileStatement
  : DO BlockStatement WHILE LEFT_BRACE Expression RIGHT_BRACE SEMICOLON
  ;
```

The body runs once before the first condition check. After that it behaves like a
while loop. `break` exits, and `continue` proceeds to the condition check.

### ForStatement

```text
ForStatement
  : FOR LEFT_BRACE ForStatementInitOpt SEMICOLON ExpressionOpt SEMICOLON ExpressionOpt RIGHT_BRACE BlockStatement
  ;
```

The evaluator creates a loop-local environment.

1. Evaluate the optional initializer once. It can be a variable statement or an
   expression.
2. Evaluate the optional condition before each iteration. A missing condition is
   treated as `true`.
3. Execute the body.
4. Evaluate the optional update expression after normal body completion or
   `continue`.
5. Return the last completed body result, or `null`.

`break` exits the loop.

### FunctionDeclaration

```text
FunctionDeclaration
  : DEF IDENTIFIER LEFT_BRACE FormalParameterListOpt RIGHT_BRACE BlockStatement
  ;
```

Creates an `EvalRuntimeFunction`, captures the current environment for lexical
scope, defines the function name in the current environment, and returns `null`.

### ReturnStatement

```text
ReturnStatement
  : RETURN ReturnValueOpt SEMICOLON
  ;
```

Evaluates the optional return expression, or uses `null` for a bare `return`.
`Eval.execute` wraps the value in `returnSignal`. User function calls catch that
signal and convert it into the call result.

A `return` outside a function remains a runtime error signal.

### BreakStatement

```text
BreakStatement
  : BREAK SEMICOLON
  ;
```

Throws `breakSignal`. Loop evaluators catch it and exit the nearest loop. A
`break` outside a loop remains a runtime error signal.

### ContinueStatement

```text
ContinueStatement
  : CONTINUE SEMICOLON
  ;
```

Throws `continueSignal`. Loop evaluators catch it and skip the rest of the
current iteration. A `continue` outside a loop remains a runtime error signal.

### ClassDeclaration

```text
ClassDeclaration
  : CLASS IDENTIFIER ClassExtendsOpt BlockStatement
  ;
```

The class name must be an identifier. The optional superclass expression is
evaluated and must produce a class value. The class body must contain function
declarations; each function becomes a method stored on the runtime class.

The class value is defined in the current environment and the declaration
returns `null`.

## Expressions

```text
Expression
  : AssignmentExpression
  ;
```

`Eval.evaluateExpression(_:in:)` dispatches by `Expression` case.

### Literals

```text
Literal
  : NumericLiteral
  | StringLiteral
  | BooleanLiteral
  | NullLiteral
  ;
```

- Whole numeric literals become `int`.
- Non-whole numeric literals become `double`.
- Strings become `string`.
- Booleans become `bool`.
- `null` becomes `null`.

### IdentifierExpression

```text
PrimaryExpression
  : IDENTIFIER
  ;
```

Looks up the identifier in the current environment chain.

### AssignmentExpression

```text
AssignmentExpression
  : LogicalOrExpression
  | LeftHandSideExpression AssignmentOperator AssignmentExpression
  ;
```

The left side is resolved into an assignment target:

- identifier binding
- object field
- array element

For `=`, the right side is evaluated and assigned directly. For `+=`, `-=`,
`*=`, and `/=`, the current target value is read, the matching binary operation
is applied, and the result is written back. Assignment returns the assigned
value.

### Logical Expressions

```text
LogicalOrExpression
  : LogicalAndExpression
  | LogicalOrExpression LOGICAL_OR LogicalAndExpression
  ;

LogicalAndExpression
  : EqualityExpression
  | LogicalAndExpression LOGICAL_AND EqualityExpression
  ;
```

Logical operators short-circuit:

- `&&` returns `false` without evaluating the right side when the left side is
  falsy.
- `||` returns `true` without evaluating the right side when the left side is
  truthy.

When the right side is needed, both operands are converted through truthiness and
the result is a boolean.

### EqualityExpression

```text
EqualityExpression
  : RelationalExpression
  | EqualityExpression EQUALITY RelationalExpression
  ;
```

`==` and `!=` compare numbers, strings, booleans, and `null`. Mixed `int` and
`double` values compare by numeric value. Other cross-type comparisons are not
equal.

### RelationalExpression

```text
RelationalExpression
  : AdditiveExpression
  | RelationalExpression RELATIONAL AdditiveExpression
  ;
```

`>`, `>=`, `<`, and `<=` require numeric operands and return booleans.

### AdditiveExpression

```text
AdditiveExpression
  : MultiplicativeExpression
  | AdditiveExpression (ADD | MINUS) MultiplicativeExpression
  ;
```

`+` supports numeric addition and string concatenation. `-` requires numeric
operands.

### MultiplicativeExpression

```text
MultiplicativeExpression
  : UnaryExpression
  | MultiplicativeExpression (MUL | DIV) UnaryExpression
  ;
```

`*` and `/` require numeric operands. Numeric results preserve `int` when both
operands are ints and the result is still a whole number; otherwise the result is
`double`.

### UnaryExpression

```text
UnaryExpression
  : LeftHandSideExpression
  | UNARY UnaryExpression
  | MINUS UnaryExpression
  ;
```

`!` returns the negated truthiness of its argument. Unary `-` requires an `int`
or `double`.

### MemberExpression

```text
MemberExpression
  : PrimaryExpression
  | MemberExpression DOT IDENTIFIER
  | MemberExpression LEFT_SQUARE_BRACKET Expression RIGHT_SQUARE_BRACKET
  ;
```

For objects:

- Dot access uses the identifier name directly.
- Computed access evaluates the property and requires a string key.
- Missing fields return `null`.
- If a field is missing but the class has a method with that name, the method is
  returned with `self` bound to the receiver object.

For arrays:

- Only computed access is valid.
- The index must be an `int`.
- Out-of-bounds reads return `null`.
- Out-of-bounds writes throw an invalid operand error.

### CallExpression

```text
CallExpression
  : Callee Arguments
  ;
```

The callee is evaluated first, then arguments are evaluated left to right.

For user functions:

1. Check arity.
2. Create a call environment under the function closure.
3. Bind parameters to argument values.
4. Execute the function body.
5. Return a caught `returnSignal`, or `null` if the body completes without
   `return`.

For native functions, arity is checked when the native function declares an
expected count, then the Swift closure is called.

Calling any other value throws `notCallable`.

### SelfExpression

```text
SelfExpression
  : SELF
  ;
```

Looks up `self` in the current environment. Method binding creates an
environment that defines `self` as the receiver object.

### SuperExpression

```text
SuperExpression
  : SUPER
  ;
```

`super` is parsed but not evaluated yet. Evaluating a `super` expression throws
an unimplemented runtime error.

### NewExpression

```text
NewExpression
  : NEW MemberExpression Arguments
  ;
```

The callee is evaluated and must be a class. Arguments are evaluated left to
right. The interpreter creates an object linked to the class, then calls an
inherited or direct `init` method when present with `self` bound to the new
object.

If no initializer exists, passing arguments is an arity error.

### ArrayLiteral

```text
ArrayLiteral
  : LEFT_SQUARE_BRACKET ArrayElementListOpt RIGHT_SQUARE_BRACKET
  ;
```

Elements are evaluated left to right and stored in a mutable runtime array.

### DictionaryLiteral

```text
DictionaryLiteral
  : LEFT_CURLY_BRACE DictionaryEntryListOpt RIGHT_CURLY_BRACE
  ;
```

Creates a plain runtime object. Keys must be identifiers or string literals.
Values are evaluated left to right and stored on the object's field dictionary.

## Truthiness

`isTruthy` is used by conditionals, loops, and logical operators.

- `bool`: its own value
- `int`: true when greater than `0`
- `double`: true when greater than `0.0`
- `null`: false
- all other runtime values: true

## Native Builtins

The root environment installs these native functions:

```text
print(...)
len(value)
type(value)
str(value)
append(array, value)
pop(array)
keys(object)
has(object, key)
set(object, key, value)
```

- `print` writes joined `displayValue` strings and returns `null`.
- `len` supports strings, arrays, and objects.
- `type` returns the runtime type name.
- `str` returns a string using `displayValue`.
- `append` mutates an array and returns it.
- `pop` removes and returns the last array element, or `null`.
- `keys` returns sorted object field names.
- `has` checks whether an object field exists.
- `set` writes an object field and returns the object.

## Runtime Errors And Signals

`EvalRuntimeError` is used for both user-visible errors and internal
control-flow signals:

```text
unimplemented
undefinedVariable
invalidOperand
invalidAssignmentTarget
notCallable
arityMismatch
returnSignal
breakSignal
continueSignal
internalError
```

`returnSignal`, `breakSignal`, and `continueSignal` are intended to be caught by
function and loop evaluators. If they escape to the top level, they are reported
as runtime errors.
