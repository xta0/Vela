//
//  BinaryEval.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

extension Eval {
  static func evaluateBinary(_ node: BinaryExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    let left = try evaluate(node.left, in: env)
    let right = try evaluate(node.right, in: env)

    switch node.operatorValue {
    case "+":
      switch (left, right) {
      case let (.number(a), .number(b)):
        return .number(a + b)
      case let (.string(a), .string(b)):
        return .string(a + b)
      default:
        throw .invalidOperand("+")
      }

    case "-":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand("-")
      }
      return .number(a - b)

    case "*":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand("*")
      }
      return .number(a * b)

    case "/":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand("/")
      }
      return .number(a / b)

    case ">":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand(">")
      }
      return .bool(a > b)

    case ">=":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand(">=")
      }
      return .bool(a >= b)

    case "<":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand("<")
      }
      return .bool(a < b)

    case "<=":
      guard case let .number(a) = left, case let .number(b) = right else {
        throw .invalidOperand("<=")
      }
      return .bool(a <= b)

    case "==":
      return .bool(isEqual(left, right))

    case "!=":
      return .bool(!isEqual(left, right))

    default:
      throw .unimplemented(node.operatorValue)
    }
  }

  private static func isEqual(_ left: EvalRuntimeValue, _ right: EvalRuntimeValue) -> Bool {
    switch (left, right) {
    case let (.number(a), .number(b)):
      return a == b
    case let (.string(a), .string(b)):
      return a == b
    case let (.bool(a), .bool(b)):
      return a == b
    case (.null, .null):
      return true
    default:
      return false
    }
  }
}
