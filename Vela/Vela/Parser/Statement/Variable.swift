//
//  Variable.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

extension Parser {
  // VariableStatementInit
  //   : KEYWORD("let") VariableDeclarationList
  //   ;
  //
  // Examples:
  // `let x`
  // `let x = 1, y = 2`
  func variableStatementInitBuilder() throws -> VariableStatement {
    try eat(.KEYWORD(keyword: "let"))
    let declarations: [VariableDeclaration] = try variableDeclarationListBuilder()
    return VariableStatement(declarations: declarations)
  }

  // VariableStatement
  //   : KEYWORD("let") VariableDeclarationList SEMICOLON
  //   ;
  //
  // Examples:
  // `let x;`
  // `let x = 1;`
  // `let x = 1, y = 2;`
  func variableStatementBuilder() throws -> VariableStatement {
    let statement = try variableStatementInitBuilder()
    try eat(.SEMICOLON)
    return statement
  }

  // VariableDeclarationList
  //   : VariableDeclaration
  //   | VariableDeclarationList ',' VariableDeclaration
  //   ;
  //
  // Examples:
  // `x`
  // `x = 1, y = 2`
  func variableDeclarationListBuilder() throws -> [VariableDeclaration] {
    var declarations: [VariableDeclaration] = try [variableDeclarationBuilder()]
    while lookahead?.type == .COMMA {
      try eat(.COMMA)
      try declarations.append(variableDeclarationBuilder())
    }
    return declarations
  }

  // VariableDeclaration
  //   : Identifier VariableInitializer?
  //   ;
  //
  // Examples:
  // `x`
  // `x = 1`
  // `total = a + b`
  func variableDeclarationBuilder() throws -> VariableDeclaration {
    let identifierExp = try identifierBuilder()
    guard case let .identifierExpression(varName) = identifierExp else {
      throw ParserError.unexpectedToken(actual: lookahead?.type ?? .UNKNOWN, expected: .IDENTIFIER)
    }

    var initializer: Expression?
    if lookahead?.type != .SEMICOLON && lookahead?.type != .COMMA {
      initializer = try variableInitializerBuilder()
    }
    return VariableDeclaration(id: varName.value, initializer: initializer)
  }

  // VariableInitializer
  //   : SIMPLE_ASSIGNMENT AssignmentExpression
  //   ;
  //
  // Examples:
  // `= 1`
  // `= x && y`
  // `= y = 1`
  func variableInitializerBuilder() throws -> Expression {
    try eat(.SIMPLE_ASSIGNMENT)
    return try assignmentExpressionBuilder()
  }
}
