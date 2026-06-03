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
  //   | AdditiveExpression (ADD | MINUS) MultiplicativeExpression
  //   ;
  //
  // Examples:
  // `1`
  // `1 + 2`
  // `1 + 2 - 3`
  //
  // Left recursive:
  //
  // AdditiveExpression → AdditiveExpression (ADD | MINUS) MultiplicativeExpression
  // MultiplicativeExpression (ADD | MINUS) MultiplicativeExpression
  // MultiplicativeExpression (ADD | MINUS) MultiplicativeExpression (ADD | MINUS) MultiplicativeExpression
  // ...
  func additiveExpressionBuilder() throws -> Expression {
    // fallback to multiplacationExp
    try binaryExpressionBuilder([.ADD, .MINUS], operand: multiplicativeExpressionBuilder)
  }

  // MultiplicativeExpression
  //   : UnaryExpression
  //   | MultiplicativeExpression (MUL | DIV) UnaryExpression
  //   ;
  //
  // Examples:
  // `x`
  // `2 * 3`
  // `8 / 4 * 2`
  //
  // Left recursive:
  //
  // MultiplicativeExpression → MultiplicativeExpression (MUL | DIV) UnaryExpression
  // UnaryExpression (MUL | DIV) UnaryExpression
  // UnaryExpression (MUL | DIV) UnaryExpression (MUL | DIV) UnaryExpression
  // ...
  func multiplicativeExpressionBuilder() throws -> Expression {
    // fallback to unaryExp
    try binaryExpressionBuilder([.MUL, .DIV], operand: unaryExpressionBuilder)
  }
}

extension Parser {
  func binaryExpressionBuilder(_ operatorType: TokenType, operand: () throws -> Expression) throws -> Expression {
    try binaryExpressionBuilder([operatorType], operand: operand)
  }

  func binaryExpressionBuilder(_ operators: [TokenType], operand: () throws -> Expression) throws -> Expression {
    var left = try operand()
    while let operatorType = lookahead?.type, operators.contains(operatorType) {
      let operatorValue = try eat(operatorType).value
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
