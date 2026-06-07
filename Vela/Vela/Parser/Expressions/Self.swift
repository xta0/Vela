//
//  Self.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  /// SelfExpression
  ///  : 'self'
  ///  ;
  ///
  /// Examples:
  /// `self`
  /// `self.x`
  /// `self["x"]`
  func selfExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "self"))
    let node = SelfExpression()
    return .selfExpression(node)
  }

  /// SuperExpression
  ///  : 'super'
  ///  ;
  ///
  /// Examples:
  /// `super`
  /// `super(x, y)`
  func superExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "super"))
    let node = SuperExpression()
    return .superExpression(node)
  }
}
