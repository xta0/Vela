//
//  ArrayLiteral.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

import Foundation

extension Parser {
  /// ArrayLiteral
  ///   : LEFT_SQUARE_BRACKET ArrayElementListOpt RIGHT_SQUARE_BRACKET
  ///   ;
  ///
  /// ArrayElementList
  ///   : LogicalOrExpression
  ///   | ArrayElementList COMMA LogicalOrExpression
  ///   ;
  ///
  /// Examples:
  /// `[]`
  /// `[x, y + 1, foo()]`
  func arrayLiteralBuilder() throws -> Expression {
    try eat(.LEFT_SQUARE_BRACKET)

    let elements = lookahead?.type == .RIGHT_SQUARE_BRACKET
      ? []
      : try arrayElementListBuilder()

    try eat(.RIGHT_SQUARE_BRACKET)

    return .arrayLiteral(ArrayLiteral(elements: elements))
  }

  private func arrayElementListBuilder() throws -> [Expression] {
    var elements = try [logicalOrExpressionBuilder()]

    while lookahead?.type == .COMMA {
      try eat(.COMMA)
      try elements.append(logicalOrExpressionBuilder())
    }

    return elements
  }
}
