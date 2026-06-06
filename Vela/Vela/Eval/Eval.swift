//
//  Eval.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

enum Eval {
  static let globalEnv = EvalEnvironment()

  static func eval(_ program: Program) throws(EvalRuntimeError) -> EvalRuntimeValue {
    try eval(program, in: globalEnv)
  }

  static func eval(_ program: Program, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    var result: EvalRuntimeValue = .null
    for statement in program.body {
      result = try Eval.execute(statement, in: env)
    }
    return result
  }
}
