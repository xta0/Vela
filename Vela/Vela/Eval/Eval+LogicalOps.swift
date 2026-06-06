//
//  Eval+LogicalOps.swift
//  Vela
//
//  Created by Tao Xu on 6/3/26.
//

extension Eval {
  static func applyLogical(_ operatorValue: String,
                           _ left: EvalRuntimeValue,
                           _ right: EvalRuntimeValue) throws(EvalRuntimeError) -> EvalRuntimeValue
  {
    if operatorValue == "&&" {
      return .bool(left.isTruthy && right.isTruthy)
    } else if operatorValue == "||" {
      return .bool(left.isTruthy || right.isTruthy)
    } else {
      throw .unimplemented("op: \(operatorValue)")
    }
  }
}
