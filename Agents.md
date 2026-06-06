# Agents

## Project

Vela is a Swift/Xcode project for a toy language parser and interpreter.

The parser produces AST nodes under `Vela/Vela/Parser`. The interpreter lives
under `Vela/Vela/Interpreter` and evaluates AST nodes into `EvalRuntimeValue`.

## Useful Commands

Build the app:

```sh
xcodebuild build -scheme Vela -project Vela/Vela.xcodeproj -destination 'platform=macOS'
```

Run parser and interpreter unit tests:

```sh
xcodebuild test -scheme Vela -project Vela/Vela.xcodeproj -destination 'platform=macOS' -only-testing:VelaTests/VelaParserTests -only-testing:VelaTests/VelaEvalTests
```

Avoid relying on the full scheme as the only verification signal until the
`VelaUITests` bundle issue is fixed.

## Code Guidelines

- Prefer the existing recursive-descent parser style.
- Keep token kinds precise. `ADD`, `MINUS`, `MUL`, and `DIV` are separate token
  types; parser builders can group them by precedence when needed.
- Keep AST node definitions in `Parser/Node.swift`.
- Keep expression parser helpers in `Parser/Expressions`.
- Keep statement parser helpers in `Parser/Statement`.
- Keep interpreter behavior split by expression and statement files.
- Add focused tests for parser shape and runtime behavior when adding language
  features.

## Interpreter Status

Implemented:

- Literals
- Binary arithmetic/comparison/equality
- Unary `!` and unary `-`
- Identifier lookup
- Variable declarations
- Assignment and compound assignment
- Block statements with child environments
- If statements
- Logical expression evaluation with short-circuiting
- Dictionary literal evaluation with identifier and string literal keys

Not implemented yet:

- Array literal evaluation
- Loops
- Functions and calls
- Return propagation
- Objects/classes

## Recommended Next Step

Implement array literal evaluation.

This should likely add an `array([EvalRuntimeValue])` runtime case before the
interpreter handles `.arrayLiteral`.
