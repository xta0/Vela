//
//  Eval.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

struct Eval {
  static let globalEnv = EvalEnvironment()

  static func eval(_ program: Program) throws(EvalRuntimeError) -> EvalRuntimeValue {
    var result: EvalRuntimeValue = .null
    for statement in program.body {
      result = try Eval.execute(statement, in: globalEnv)
    }
    return result
  }
}
