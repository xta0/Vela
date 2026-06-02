//
//  Block.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

extension Parser {
  // BlockStatement
  //   : LEFT_CURLY_BRACE StatementList? RIGHT_CURLY_BRACE
  //   ;
  //
  // Examples:
  // `{}`
  // `{ 1; let x = 2; }`
  func blockStatementBuilder() throws -> BlockStatement {
    try eat(.LEFT_CURLY_BRACE)

    let body: [Statement]
    if lookahead?.type != .RIGHT_CURLY_BRACE {
      body = try statementListBuilder(stopTokenType: .RIGHT_CURLY_BRACE)
    } else {
      body = []
    }

    try eat(.RIGHT_CURLY_BRACE)

    return BlockStatement(body: body)
  }
}
