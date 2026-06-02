//
//  Empty.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

extension Parser {
  // EmptyStatement
  //   : SEMICOLON
  //   ;
  //
  // Examples:
  // `;`
  func emptyStatementBuilder() throws -> EmptyStatement {
    try eat(.SEMICOLON)
    return EmptyStatement()
  }
}
