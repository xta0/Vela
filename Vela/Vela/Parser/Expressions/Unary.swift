//
//  Unary.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  // UnaryExpression
  //   : LeftHandSideExpression
  //   | UNARY UnaryExpression
  //   ;
  //
  // Examples:
  // `x`
  // `!x`
  // `-x`
  // `!!x`
  // `!(x && y)`
  //
  // Unary is tighter than multiplication and looser than primary/identifier
  // parsing. That makes `!x * y` parse as `(!x) * y`, while `!(x && y)` keeps
  // the parenthesized logical expression as the unary argument.
  //
  // Unary is right-recursive, so repeated operators group from right to left:
  // `!!x` parses as `!(!x)`.
  func unaryExpressionBuilder() throws -> Expression {
    let op: String?
    switch lookahead?.type {
    case .UNARY(op: "!"):
      op = try eat(.UNARY(op: "!")).value
    case .MINUS:
      op = try eat(.MINUS).value
    default:
      op = nil
    }
    if let op {
      let exp = try UnaryExpression(operatorValue: op, argument: unaryExpressionBuilder())
      return .unaryExpression(exp)
    }
    return try leftHandSideExpressionBuilder()
  }
}
