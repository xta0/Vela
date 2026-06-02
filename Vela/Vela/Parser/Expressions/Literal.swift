//
//  Literal.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

// MARK: Literal

extension Parser {
  // Literal
  //   : NumericLiteral
  //   | StringLiteral
  //   | BooleanLiteral
  //   | NullLiteral
  //   ;
  //
  // Examples:
  // `42`
  // `"hello"`
  // `true`
  // `false`
  // `null`
  func literalBuilder() throws -> Expression {
    guard let lookahead else {
      throw ParserError.unexpectedLiteralProduction
    }

    switch lookahead.type {
    case .NUMBER:
      return try .numericLiteral(numericLiteralBuilder())
    case .STRING:
      return try .stringLiteral(stringLiteralBuilder())
    case .KEYWORD(keyword: "true"):
      return try .booleanLiteral(booleanLiteralBuilder(true))
    case .KEYWORD(keyword: "false"):
      return try .booleanLiteral(booleanLiteralBuilder(false))
    case .KEYWORD(keyword: "null"):
      return try .nullLiteral(nullLiteralBuilder())
    default:
      throw ParserError.unexpectedLiteralProduction
    }
  }

  // NumericLiteral
  //   : NUMBER
  //   ;
  //
  // Examples:
  // `0`
  // `42`
  func numericLiteralBuilder() throws -> NumericLiteral {
    let token = try eat(.NUMBER)
    return NumericLiteral(value: Double(token.value) ?? 0)
  }

  // StringLiteral
  //   : STRING
  //   ;
  //
  // Examples:
  // `"hello"`
  // `'hello'`
  func stringLiteralBuilder() throws -> StringLiteral {
    let token = try eat(.STRING)
    return StringLiteral(value: String(token.value.dropFirst().dropLast()))
  }

  // BooleanLiteral
  //   : 'true'
  //   | 'false'
  //   ;
  //
  // Examples:
  // `true`
  // `false`
  func booleanLiteralBuilder(_ value: Bool) throws -> BooleanLiteral {
    let keyword = value ? "true" : "false"
    try eat(.KEYWORD(keyword: keyword))
    return BooleanLiteral(value: value)
  }

  // NullLiteral
  //   : 'null'
  //   ;
  //
  // Examples:
  // `null`
  func nullLiteralBuilder() throws -> NullLiteral {
    try eat(.KEYWORD(keyword: "null"))
    return NullLiteral(value: nil)
  }

  func isLiteral() -> Bool {
    lookahead?.type == .NUMBER ||
      lookahead?.type == .STRING ||
      lookahead?.type == .KEYWORD(keyword: "true") ||
      lookahead?.type == .KEYWORD(keyword: "false") ||
      lookahead?.type == .KEYWORD(keyword: "null")
  }
}
