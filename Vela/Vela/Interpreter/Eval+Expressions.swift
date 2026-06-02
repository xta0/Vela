//
//  Eval+Expressions.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

extension Eval {
  static func evaluate(_ expression: Expression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    switch expression {
    case let .numericLiteral(node):
      return .number(node.value)
    case let .stringLiteral(node):
      return .string(node.value)
    case let .booleanLiteral(node):
      return .bool(node.value)
    case .nullLiteral:
      return .null
    case let .binaryExpression(node):
      return try self.evaluateBinary(node, in: env)
    default:
      throw .unimplemented(expression.type)
    }
  }
}
