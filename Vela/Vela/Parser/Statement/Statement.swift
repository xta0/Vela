//
//  Statement.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

extension Parser {
  // StatementList
  //   : Statement
  //   | StatementList Statement
  //   ;
  //
  // Examples:
  // `1;`
  // `1; 2; let x = 3;`
  //
  // A StatementList is parsed with a loop because direct left recursion does
  // not terminate in recursive descent parsers.
  func statementListBuilder(stopTokenType: TokenType? = nil) throws -> [Statement] {
    let stat = try statementBuilder()
    print("[Parser] Add statement to list: [\(stat.type)]")
    var statements: [Statement] = [stat]

    while lookahead != nil, lookahead?.type != stopTokenType {
      let stat = try statementBuilder()
      print("[Parser] Add statement to list: [\(stat.type)]")
      statements.append(stat)
    }

    return statements
  }

  // Statement
  //   : ExpressionStatement
  //   | BlockStatement
  //   | EmptyStatement
  //   | VariableStatement
  //   | IfStatement
  //   | IterationStatement
  //   | FunctionDeclaration
  //   | ReturnStatement
  //   ;
  //
  // Examples:
  // `;`
  // `{ 1; }`
  // `let x = 1;`
  // `if (x) {}`
  // `while (x) {}`
  // `for (;;) {}`
  // `def add(x, y) { return x + y; }`
  // `return x;`
  // `x + 1;`
  func statementBuilder() throws -> Statement {
    guard let lookahead else {
      throw ParserError.unexpectedLiteralProduction
    }
    switch lookahead.type {
    case .SEMICOLON:
      return try .Empty(emptyStatementBuilder())
    case .LEFT_CURLY_BRACE:
      return try .Block(blockStatementBuilder())
    case .KEYWORD(keyword: "let"):
      return try .Variable(variableStatementBuilder())
    case .KEYWORD(keyword: "if"):
      return try .If(ifStatementBuilder())
    case .KEYWORD(keyword: "def"):
      return try .Function(functionDeclarationBuilder())
    case .KEYWORD(keyword: "return"):
      return try .Return(returnStatementBuilder())
    case .KEYWORD(keyword: "while"),
         .KEYWORD(keyword: "do"),
         .KEYWORD(keyword: "for"):
      return try .Iteration(iterationStatementBuilder())
    case .KEYWORD(keyword: "class"):
      return try .ClassDeclaration(classDeclarationStamentBuilder())
    default:
      return try .Expression(expressionStatementBuilder())
    }
  }
}
