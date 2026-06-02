//
//  This.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  // ThisExpression
  //  : 'this'
  //  ;
  //
  // Examples:
  // `this`
  // `this.x`
  // `this["x"]`
  func thisExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "this"))
    let node = ThisExpression()
    return .thisExpression(node)
  }

  // SuperExpression
  //  : 'super'
  //  ;
  //
  // Examples:
  // `super`
  // `super(x, y)`
  func superExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "super"))
    let node = SuperExpression()
    return .superExpression(node)
  }
}
