//
//  Expression.swift
//  ToyParser
//
//  Created by Tao Xu on 5/3/26.
//

import Foundation

extension Parser {
  // Expression
  //   : AssignmentExpression
  //   ;
  //
  // Expression starts at the lowest-precedence expression rule and lets each
  // builder delegate to the next tighter rule. Each level either consumes its
  // own operator or falls back by returning what the tighter level parsed.
  //
  // Expression precedence flows from lowest to highest:
  // AssignmentExpression
  // LogicalOrExpression
  // LogicalAndExpression
  // EqualityExpression
  // RelationalExpression
  // AdditiveExpression
  // MultiplicativeExpression
  // UnaryExpression
  // PrimaryExpression
  //
  // Logical OR (`||`) is looser than logical AND (`&&`), so `a || b && c`
  // parses as `a || (b && c)`.
  //
  // Logical AND is looser than equality, so `a && b == c` parses as
  // `a && (b == c)`.
  //
  // Equality is looser than relational, so `a == b < c` parses as
  // `a == (b < c)`.
  //
  // Examples:
  // `x = a < b` parses as `x = (a < b)`.
  // `x = a || b && c` parses as `x = (a || (b && c))`.
  // `a == b && c < d` parses as `(a == b) && (c < d)`.
  // `a + b < c * d` parses as `(a + b) < (c * d)`.
  // `x = y = 1` parses as `x = (y = 1)`.
  // `1 + 2` still parses because each looser builder falls through to the next
  // tighter builder until additive handles `+`.
  func expressionBuilder() throws -> Expression {
    try assignmentExpressionBuilder()
  }
}
