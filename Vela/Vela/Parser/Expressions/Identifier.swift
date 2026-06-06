//
//  Identifier.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

// MARK: Identifier

extension Parser {
  /// Identifier
  ///   : IDENTIFIER
  ///   ;
  ///
  /// Examples:
  /// `x`
  /// `total`
  func identifierBuilder() throws -> Expression {
    let name = try eat(.IDENTIFIER).value
    return .identifierExpression(IdentifierExpression(value: name))
  }
}
