//
//  Assignment.swift
//  ToyParser
//
//  Created by Tao Xu on 5/3/26.
//

import Foundation

extension Parser {
  // AssignmentExpression
  //   : LogicalOrExpression
  //   | LeftHandSideExpression AssignmentOperator AssignmentExpression
  //   ;
  //
  // Examples:
  // `x`
  // `x = 1`
  // `x += y`
  // `x = y = 1`
  //
  // Assignment is right-associative and should delegate to the next tighter
  // expression level for its non-assignment fallback. Logical OR is the next
  // tighter level, so `x = a || b` parses as `x = (a || b)`.
  func assignmentExpressionBuilder() throws -> Expression {
    // First parse the next tighter expression level. If no assignment operator
    // follows, this is not an assignment; return that expression unchanged.
    // This lets AssignmentExpression parse `x = 1`, `x = a || b`, `x = a < b`,
    // and plain expressions like `1 + 2`.
    var left = try logicalOrExpressionBuilder()
    guard let type = lookahead?.type, isAssignmentOp(type) else {
      return left
    }

    // check the op first
    let operatorToken = try assignmentOperator()

    // left has to be a prim op
    left = try checkValidAssignment(left, operatorToken)

    // right recursion
    return try .assignmentExpression(
      AssignmentExpression(
        operatorValue: operatorToken.value,
        left: left,
        right: assignmentExpressionBuilder()
      )
    )
  }

  // AssignmentOperator
  //   : SIMPLE_ASSIGNMENT
  //   | COMPLEX_ASSIGNMENT
  //   ;
  //
  // Examples:
  // `=`
  // `+=`
  // `-=`
  // `*=`
  // `/=`
  private func assignmentOperator() throws -> Token {
    if lookahead?.type == .SIMPLE_ASSIGNMENT {
      return try eat(.SIMPLE_ASSIGNMENT)
    }
    return try eat(.COMPLEX_ASSIGNMENT)
  }

  private func isAssignmentOp(_ op: TokenType) -> Bool {
    op == .SIMPLE_ASSIGNMENT || op == .COMPLEX_ASSIGNMENT
  }

  private func checkValidAssignment(_ lhs: Expression, _: Token) throws -> Expression {
    switch lhs {
    case .identifierExpression, .memberExpression:
      return lhs
    default:
      throw ParserError.unexpectedAssignmentOperator
    }
  }
}
