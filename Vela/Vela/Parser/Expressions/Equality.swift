//
//  Equality.swift
//  ToyParser
//
//  Created by Tao Xu on 5/9/26.
//

extension Parser {
  // EqualityExpression
  //   : RelationalExpression
  //   | EqualityExpression EQUALITY RelationalExpression
  //   ;
  //
  // Examples:
  // `a`
  // `a == b`
  // `a != b`
  // `a == b < c`
  //
  // Equality sits between logical AND and relational:
  // LogicalAndExpression delegates to EqualityExpression.
  // EqualityExpression delegates to RelationalExpression.
  //
  // This makes equality looser than relational, so `a == b < c` parses as
  // `a == (b < c)`.
  // It also makes equality tighter than logical AND, so `a && b == c` should
  // parse as `a && (b == c)`.
  //
  func equalityExpressionBuilder() throws -> Expression {
    try binaryExpressionBuilder(.EQUALITY, operand: relationalExpressionBuilder)
  }
}
