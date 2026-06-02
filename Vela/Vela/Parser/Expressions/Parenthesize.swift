//
//  Parenthesize.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  // ParenthesizedExpression
  //   : LEFT_BRACE Expression RIGHT_BRACE
  //   ;
  //
  // Examples:
  // `(1 + 2)`
  // `(x = y)`
  // `(a || b)`
  func parenthesizedExpressionBuilder() throws -> Expression {
    try eat(.LEFT_BRACE)
    let expr = try expressionBuilder()
    try eat(.RIGHT_BRACE)
    return expr
  }
}
