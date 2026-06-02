//
//  Primary.swift
//  ToyParser
//
//  Created by Tao Xu on 5/3/26.
//

import Foundation

extension Parser {
  // PrimaryExpression
  //   : Literal
  //   | ParenthesizedExpression
  //   | Identifier
  //   | ThisExpression
  //   | NewExpression
  //   ;
  //
  // Examples:
  // `42`
  // `"hello"`
  // `true`
  // `x`
  // `(1 + 2)`
  // `this`
  // `new Point(1, 2)`
  func primaryExpressionBuilder() throws -> Expression {
    if isLiteral() {
      return try literalBuilder()
    }
    switch lookahead?.type {
    case .LEFT_BRACE:
      return try parenthesizedExpressionBuilder()
    case .IDENTIFIER:
      return try identifierBuilder()
    case .KEYWORD(keyword: "this"):
      return try thisExpressionBuilder()
    case .KEYWORD(keyword: "new"):
      return try newExpressionBuilder()
    default:
      return try leftHandSideExpressionBuilder()
    }
  }
}
