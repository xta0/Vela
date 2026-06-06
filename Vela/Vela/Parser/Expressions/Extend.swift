//
//  Extend.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  /// ClassExtends
  ///  : 'extends' Identifier
  ///  ;
  ///
  /// Examples:
  /// `extends Shape`
  /// `extends Point`
  func classExtendExpressionBuilder() throws -> Expression {
    try eat(.KEYWORD(keyword: "extends"))
    return try identifierBuilder()
  }
}
