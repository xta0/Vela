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
    case let .Expression(exprStmt):
      return try Eval.evaluate(exprStmt.value, in: env)
    default:
      throw .unimplemented(statement.type)
    }
  }
}
