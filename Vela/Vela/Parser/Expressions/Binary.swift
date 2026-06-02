//
//  Binary.swift
//  ToyParser
//
//  Created by Tao Xu on 5/3/26.
//

import Foundation

extension Parser {
  // AdditiveExpression
  //   : MultiplicativeExpression
  //   | AdditiveExpression ADD MultiplicativeExpression
  //   ;
  //
  // Examples:
  // `1`
  // `1 + 2`
  // `1 + 2 - 3`
  //
  // Left recursive:
  //
  // AdditiveExpression → AdditiveExpression ADD MultiplicativeExpression
  // MultiplicativeExpression ADD MultiplicativeExpression
  // MultiplicativeExpression ADD MultiplicativeExpression ADD MultiplicativeExpression
  // ...
  func additiveExpressionBuilder() throws -> Expression {
    // fallback to multiplacationExp
    try binaryExpressionBuilder(.ADD, operand: multiplicativeExpressionBuilder)
  }

  // MultiplicativeExpression
  //   : UnaryExpression
  //   | MultiplicativeExpression MUL UnaryExpression
  //   ;
  //
  // Examples:
  // `x`
  // `2 * 3`
  // `8 / 4 * 2`
  //
  // Left recursive:
  //
  // MultiplicativeExpression → MultiplicativeExpression MUL UnaryExpression
  // UnaryExpression MUL UnaryExpression
  // UnaryExpression MUL UnaryExpression MUL UnaryExpression
  // ...
  func multiplicativeExpressionBuilder() throws -> Expression {
    // fallback to unaryExp
    try binaryExpressionBuilder(.MUL, operand: unaryExpressionBuilder)
  }
}

extension Parser {
  func binaryExpressionBuilder(_ op: TokenType, operand: () throws -> Expression) throws -> Expression {
    var left = try operand()
    while lookahead?.type == op {
      let operatorValue = try eat(op).value
      let right = try operand()
      left = .binaryExpression(
        BinaryExpression(
          operatorValue: operatorValue,
          left: left,
          right: right
        )
      )
    }
    return left
  }
}
