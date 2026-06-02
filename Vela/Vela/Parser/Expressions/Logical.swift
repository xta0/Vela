//
//  Logical.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  // LogicalOrExpression
  //   : LogicalAndExpression
  //   | LogicalOrExpression LOGICAL_OR LogicalAndExpression
  //   ;
  //
  // Examples:
  // `a`
  // `a || b`
  // `a || b && c`
  //
  // Logical OR (`||`) is lower precedence than logical AND (`&&`):
  // `a || b && c` parses as `a || (b && c)`.
  //
  // This is the first level below assignment, so AssignmentExpression delegates
  // here. If there is no `||`, this builder falls through to LogicalAndExpression
  // unchanged.
  func logicalOrExpressionBuilder() throws -> Expression {
    try logicalExpressionBuilder(.LOGICAL_OR, operand: logicalAndExpressionBuilder)
  }

  // LogicalAndExpression
  //   : EqualityExpression
  //   | LogicalAndExpression LOGICAL_AND EqualityExpression
  //   ;
  //
  // Examples:
  // `a`
  // `a && b`
  // `a && b == c`
  //
  // Logical AND (`&&`) is higher precedence than logical OR, but lower
  // precedence than equality:
  // `a && b == c` parses as `a && (b == c)`.
  //
  // If there is no `&&`, this builder falls through to EqualityExpression
  // unchanged.
  func logicalAndExpressionBuilder() throws -> Expression {
    try logicalExpressionBuilder(.LOGICAL_AND, operand: equalityExpressionBuilder)
  }

  private func logicalExpressionBuilder(_ op: TokenType, operand: () throws -> Expression) throws -> Expression {
    var left = try operand()
    while lookahead?.type == op {
      let operatorValue = try eat(op).value
      let right = try operand()
      left = .logicalExpression(
        LogicalExpression(
          operatorValue: operatorValue,
          left: left,
          right: right
        )
      )
    }
    return left
  }
}
