# Vela

Vela is a Swift/Xcode project for a small executable toy language. It includes a
hand-written recursive descent parser, AST debug/JSON output, and a tree-walking
interpreter with mutable runtime values and lexical environments.

The app presents two editors:

- Left editor: source code.
- Right editor: parse tree, AST JSON, eval result, or runtime environment JSON.

## Language Features

Implemented language features include:

- Literals: numbers, strings, booleans, and `null`
- Variables with `let`
- Arithmetic, comparison, equality, logical, unary, assignment, and compound
  assignment expressions
- Blocks with child scopes
- `if` / `else`
- `while`, `do while`, and `for`
- `break` and `continue`
- Function declarations, calls, lexical closures, and `return`
- Arrays, indexing, mutation, `append`, and `pop`
- Dictionary-style object literals and object member access
- Classes, inheritance metadata, instance creation with `new`, methods, `self`,
  and initializer dispatch
- Native builtins: `print`, `len`, `type`, `str`, `append`, `pop`, `keys`, `has`,
  and `set`

`super` calls are parsed but not evaluated yet.

## Project Layout

```text
Vela/
  Vela.xcodeproj
  Vela/
    ContentView.swift
    Parser/
      Parser.swift
      Node.swift
      Token.swift
      Tokenizer.swift
      Expressions/
      Statement/
    Eval/
      Eval.swift
      Eval+Statement.swift
      Eval+Expressions.swift
      EvalRuntime.swift
      EvalEnvironment.swift
  VelaTests/
    VelaParserTests.swift
    VelaEvalTests.swift
Parser.md
Eval.md
```

## How It Works

Parsing starts in `Parser.parse(_:)`. The tokenizer produces tokens lazily, and
the parser's builder methods consume those tokens into AST nodes. The parser can
render either a tree view or JSON for inspection.

Evaluation starts in `Eval.eval(_:)`. The interpreter executes statements in
order, evaluates expressions recursively, stores bindings in `EvalEnvironment`,
and returns the last top-level statement result. Structured eval results are
rendered as pretty JSON in the app's right editor.

For deeper implementation notes:

- `Parser.md` describes the grammar and recursive descent parser.
- `Eval.md` describes interpreter behavior for statements and expressions.

## Useful Commands

Build the app:

```sh
xcodebuild build -scheme Vela -project Vela/Vela.xcodeproj -destination 'platform=macOS'
```

Run parser and interpreter tests:

```sh
xcodebuild test -scheme Vela -project Vela/Vela.xcodeproj -destination 'platform=macOS' -only-testing:VelaTests/VelaParserTests -only-testing:VelaTests/VelaEvalTests
```

The focused parser/eval test command is the preferred verification signal until
the UI test bundle issue is fixed.

## Example

```vela
class Point {
  def init(x, y) {
    self.x = x;
    self.y = y;
  }

  def lengthSquared() {
    return self.x * self.x + self.y * self.y;
  }
}

let point = new Point(3, 4);
let summary = {
  length: point.lengthSquared(),
  kind: type(point)
};

summary;
```

The final `summary;` expression is the program result. In the app, the eval view
shows it as structured JSON.
