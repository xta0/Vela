//
//  Eval+Expressions.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

extension Eval {
  static func evaluateExpression(_ expression: Expression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    switch expression {
    case let .numericLiteral(node):
      if node.value.truncatingRemainder(dividingBy: 1) == 0 {
        return .int(Int(node.value))
      }
      return .double(node.value)
    case let .stringLiteral(node):
      return .string(node.value)
    case let .booleanLiteral(node):
      return .bool(node.value)
    case .nullLiteral:
      return .null
    case let .binaryExpression(node):
      return try self.evaluateBinary(node, in: env)
    case let .identifierExpression(node):
      return try env.lookup(node.value)
    case let .assignmentExpression(node):
      return try self.evaluateAssignment(node, in: env)
    case let .unaryExpression(node):
      return try self.evaluateUnary(node, in: env)
    default:
      throw .unimplemented(expression.type)
    }
  }
}

// MARK: Unary Expression

extension Eval {
  static func evaluateUnary(_ node: UnaryExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    let argument = try evaluateExpression(node.argument, in: env)

    switch node.operatorValue {
    case "!":
      return .bool(!argument.isTruthy)
    case "-":
      switch argument {
      case let .int(value):
        return .int(-value)
      case let .double(value):
        return .double(-value)
      default:
        throw .invalidOperand("-")
      }
    default:
      throw .unimplemented(node.operatorValue)
    }
  }
}

// MARK: Binary Expression

extension Eval {
  static func evaluateBinary(_ node: BinaryExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    let left = try evaluateExpression(node.left, in: env)
    let right = try evaluateExpression(node.right, in: env)
    return try applyBinary(node.operatorValue, left, right)
  }
}

// MARK: Assignment Expression

extension Eval {
  static func evaluateAssignment(_ node: AssignmentExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // left node is an identifier
    guard case let .identifierExpression(identifier) = node.left else {
       throw .invalidAssignmentTarget
    }
    var value = try self.evaluateExpression(node.right, in: env)

    switch node.operatorValue {
    case "=":
      try env.assign(identifier.value, value)
    case "+=":
      let current = try env.lookup(identifier.value)
      value = try applyBinary("+", current, value)
      try env.assign(identifier.value, value)
    case "-=":
      let current = try env.lookup(identifier.value)
      value = try applyBinary("-", current, value)
      try env.assign(identifier.value, value)
    case "*=":
      let current = try env.lookup(identifier.value)
      value = try applyBinary("*", current, value)
      try env.assign(identifier.value, value)
    case "/=":
      let current = try env.lookup(identifier.value)
      value = try applyBinary("/", current, value)
      try env.assign(identifier.value, value)
    default:
      throw .unimplemented(node.operatorValue)
    }

    return value
  }
}
