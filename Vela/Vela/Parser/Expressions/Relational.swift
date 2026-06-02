//
//  Relational.swift
//  ToyParser
//
//  Created by Tao Xu on 5/9/26.
//

extension Parser {
  // RelationalExpression
  //   : AdditiveExpression
  //   | RelationalExpression RELATIONAL AdditiveExpression
  //   ;
  //
  // Examples:
  // `a`
  // `a < b`
  // `a >= b`
  // `x + 5 > 10`
  //
  // Relational sits between equality and additive:
  // EqualityExpression delegates to RelationalExpression.
  // RelationalExpression delegates to AdditiveExpression.
  //
  // That gives `x = a < b + 1` this shape:
  // `x = (a < (b + 1))`
  func relationalExpressionBuilder() throws -> Expression {
    try binaryExpressionBuilder(.RELATIONAL, operand: additiveExpressionBuilder)
  }
}
