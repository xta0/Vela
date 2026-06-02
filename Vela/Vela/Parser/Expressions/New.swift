//
//  New.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  // NewExpression
  //  : 'new' MemberExpression Arguments
  //  ;
  //
  // Examples:
  // `new Point()`
  // `new Point(1, 2)`
  // `new MyNameSpace.Point(1, 2)`
  func newExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "new"))
    let node = try NewExpression(
      callee: memberExpressionBuilder(),
      arguments: argumentsExpressionBuilder()
    )
    return .newExpression(node)
  }
}
