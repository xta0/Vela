//
//  Eval+Statements.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//
import Foundation

extension Eval {
  static func execute(_ statement: Statement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    switch statement {
    case .Empty:
      return .null
    case let .Block(block):
      return try Eval.evaluateBlockStatement(block, in: env)
    case let .Expression(expr):
      return try Eval.evaluateExpression(expr.value, in: env)
    case let .Variable(stmt):
      return try Eval.evaluateVariableSetatement(stmt, in: env)
    case let .If(stmt):
      return try Eval.evaluateIfStatement(stmt, in: env)

    default:
      throw .unimplemented(statement.type)
    }
  }
}

// MARK: Block Statement

extension Eval {
  static func evaluateBlockStatement(_ stmt: BlockStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    let blockEnv = EvalEnvironment(parent: env)
    var result: EvalRuntimeValue = .null

    for statement in stmt.body {
      result = try execute(statement, in: blockEnv)
    }

    return result
  }
}

// MARK: Variable Statement

extension Eval {
  static func evaluateVariableSetatement(_ stmt: VariableStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    for declaration in stmt.declarations {
      let value: EvalRuntimeValue
      if let initializer = declaration.initializer {
        value = try evaluateExpression(initializer, in: env)
      } else {
        value = .null
      }
      env.define(declaration.id, value)
    }
    return .null
  }
}

// MARK: If Statement

extension Eval {
  static func evaluateIfStatement(_ stmt: IFStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    let condition = try evaluateExpression(stmt.condition, in: env)
    let isTrue = condition.isTruthy
    if isTrue {
      return try Eval.execute(.Block(stmt.ifBody), in: env)
    }
    if let elseBody = stmt.elseBody {
      return try Eval.execute(.Block(elseBody), in: env)
    }
    return .null
  }
}
