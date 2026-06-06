//
//  Eval+BinaryOps.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

extension Eval {
  static func applyBinary(
    _ operatorValue: String,
    _ left: EvalRuntimeValue,
    _ right: EvalRuntimeValue
  ) throws(EvalRuntimeError) -> EvalRuntimeValue {
    switch operatorValue {
    case "+":
      switch (left, right) {
      case let (.int(a), .int(b)):
        return .int(a + b)
      case let (.double(a), .double(b)):
        return .double(a + b)
      case let (.int(a), .double(b)):
        return .double(Double(a) + b)
      case let (.double(a), .int(b)):
        return .double(a + Double(b))
      case let (.string(a), .string(b)):
        return .string(a + b)
      default:
        throw .invalidOperand("+")
      }

    case "-":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand("-")
      }
      return numericResult(a - b, preferInt: isInt(left) && isInt(right))

    case "*":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand("*")
      }
      return numericResult(a * b, preferInt: isInt(left) && isInt(right))

    case "/":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand("/")
      }
      return numericResult(a / b, preferInt: isInt(left) && isInt(right))

    case ">":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand(">")
      }
      return .bool(a > b)

    case ">=":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand(">=")
      }
      return .bool(a >= b)

    case "<":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand("<")
      }
      return .bool(a < b)

    case "<=":
      guard let a = numericValue(left), let b = numericValue(right) else {
        throw .invalidOperand("<=")
      }
      return .bool(a <= b)

    case "==":
      return .bool(isEqual(left, right))

    case "!=":
      return .bool(!isEqual(left, right))

    default:
      throw .unimplemented(operatorValue)
    }
  }

  private static func isEqual(_ left: EvalRuntimeValue, _ right: EvalRuntimeValue) -> Bool {
    switch (left, right) {
    case (.int, .int), (.double, .double), (.int, .double), (.double, .int):
      return numericValue(left) == numericValue(right)
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

  private static func numericValue(_ value: EvalRuntimeValue) -> Double? {
    switch value {
    case let .int(value):
      return Double(value)
    case let .double(value):
      return value
    default:
      return nil
    }
  }

  private static func isInt(_ value: EvalRuntimeValue) -> Bool {
    guard case .int = value else {
      return false
    }
    return true
  }

  private static func numericResult(_ value: Double, preferInt: Bool) -> EvalRuntimeValue {
    if preferInt && value.truncatingRemainder(dividingBy: 1) == 0 {
      return .int(Int(value))
    }
    return .double(value)
  }
}
