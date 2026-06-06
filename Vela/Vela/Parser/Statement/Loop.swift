//
//  Loop.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  /// IterationStatement
  ///   : WhileStatement
  ///   | DoWhileStatement
  ///   | ForStatement
  ///   ;
  ///
  /// Examples:
  /// `while (x) {}`
  /// `do {} while (x);`
  /// `for (let i = 0; i < 10; i = i + 1) {}`
  func iterationStatementBuilder() throws -> IterationStatement {
    let op = lookahead?.type
    switch op {
    case .KEYWORD(keyword: "while"):
      return try whileStatement()
    case .KEYWORD(keyword: "do"):
      return try doWhileStatement()
    case .KEYWORD(keyword: "for"):
      return try forStatement()
    default:
      throw ParserError.unexpectedIterationOperator(actual: op ?? .UNSUPPORTED)
    }
  }

  /// WhileStatement
  ///   : KEYWORD("while") LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ///   ;
  ///
  /// Examples:
  /// `while (x) {}`
  /// `while (x < 10) { x = x + 1; }`
  private func whileStatement() throws -> IterationStatement {
    try eat(.KEYWORD(keyword: "while"))
    try eat(.LEFT_BRACE)
    let condition = try expressionBuilder()
    try eat(.RIGHT_BRACE)
    let block = try blockStatementBuilder()
    let statement = WhileIterationStatement(isDoWhile: false, condition: condition, body: block)
    return .whileLoop(statement)
  }

  /// DoWhileStatement
  ///   : KEYWORD("do") BlockStatement KEYWORD("while") LEFT_BRACE Expression RIGHT_BRACE SEMICOLON
  ///   ;
  ///
  /// Examples:
  /// `do {} while (x);`
  /// `do { x = x + 1; } while (x < 10);`
  private func doWhileStatement() throws -> IterationStatement {
    try eat(.KEYWORD(keyword: "do"))
    let block = try blockStatementBuilder()
    try eat(.KEYWORD(keyword: "while"))
    try eat(.LEFT_BRACE)
    let condition = try expressionBuilder()
    try eat(.RIGHT_BRACE)
    try eat(.SEMICOLON)
    let statement = WhileIterationStatement(isDoWhile: true, condition: condition, body: block)
    return .whileLoop(statement)
  }

  /// ForStatement
  ///   : KEYWORD("for") LEFT_BRACE ForStatementInit? SEMICOLON Expression? SEMICOLON Expression? RIGHT_BRACE BlockStatement
  ///   ;
  ///
  /// Examples:
  /// `for (;;) {}`
  /// `for (let i = 0; i < 10; i = i + 1) {}`
  private func forStatement() throws -> IterationStatement {
    try eat(.KEYWORD(keyword: "for"))
    try eat(.LEFT_BRACE)
    let start = lookahead?.type != .SEMICOLON ? try forStatementInit() : nil
    try eat(.SEMICOLON)
    let cond = lookahead?.type != .SEMICOLON ? try expressionBuilder() : nil
    _ = try eat(.SEMICOLON)
    let update = lookahead?.type != .RIGHT_BRACE ? try expressionBuilder() : nil
    try eat(.RIGHT_BRACE)
    let body = try blockStatementBuilder()
    let statement = ForIterationStatement(start: start,
                                          cond: cond,
                                          update: update,
                                          body: body)
    return .forLoop(statement)
  }

  /// ForStatementInit
  ///   : VariableStatementInit
  ///   | Expression
  ///   ;
  ///
  /// Examples:
  /// `let i = 0`
  /// `i = 0`
  private func forStatementInit() throws -> ForStatementInit {
    if lookahead?.type == .KEYWORD(keyword: "let") {
      return try .variable(variableStatementInitBuilder())
    }
    return try .expression(expressionBuilder())
  }
}
