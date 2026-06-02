//
//  Function.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  // FunctionDeclaration
  //   : KEYWORD("def") Identifier LEFT_BRACE FormalParameterList? RIGHT_BRACE BlockStatement
  //   ;
  //
  // Examples:
  // `def noop() {}`
  // `def add(x, y) { return x + y; }`
  func functionDeclarationBuilder() throws -> FunctionDeclarationStatement {
    try eat(.KEYWORD(keyword: "def"))
    let exp = try identifierBuilder()
    guard case let .identifierExpression(funcName) = exp else {
      throw ParserError.unexpectedToken(actual: lookahead?.type ?? .UNKNOWN, expected: .IDENTIFIER)
    }
    try eat(.LEFT_BRACE)

    let params: [String]
    if lookahead?.type != .RIGHT_BRACE {
      params = try formalParameterListBuilder()
    } else {
      params = []
    }
    try eat(.RIGHT_BRACE)
    let body = try blockStatementBuilder()
    return FunctionDeclarationStatement(name: funcName.value, params: params, body: body)
  }

  // ReturnStatement
  //   : KEYWORD("return") Expression? SEMICOLON
  //   ;
  //
  // Examples:
  // `return;`
  // `return x + 1;`
  func returnStatementBuilder() throws -> ReturnStatement {
    try eat(.KEYWORD(keyword: "return"))
    if lookahead?.type == .SEMICOLON {
      try eat(.SEMICOLON)
      return ReturnStatement(value: nil)
    }
    let exp = try expressionBuilder()
    try eat(.SEMICOLON)
    return ReturnStatement(value: exp)
  }

  // FormalParameterList
  //   : Identifier
  //   | FormalParameterList COMMA Identifier
  //   ;
  //
  // Examples:
  // `x`
  // `x, y, z`
  private func formalParameterListBuilder() throws -> [String] {
    var params: [String] = []
    let exp = try identifierBuilder()
    if case let .identifierExpression(param) = exp {
      params.append(param.value)
    }
    while lookahead?.type == .COMMA {
      try eat(.COMMA)
      let exp = try identifierBuilder()
      if case let .identifierExpression(param) = exp {
        params.append(param.value)
      }
    }
    return params
  }
}
