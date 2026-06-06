//
//  EvalError.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

enum EvalRuntimeError: Error, CustomStringConvertible {
  case undefinedVariable(String)
  case invalidOperand(String)
  case invalidAssignmentTarget
  case notCallable(EvalRuntimeValue)
  case arityMismatch(expected: Int, got: Int)
  case unimplemented(String)
  case internalError(String)
  case breakSignal
  case continueSignal
  case returnSignal(EvalRuntimeValue)

  var description: String {
    switch self {
    case let .undefinedVariable(name):
      return "Undefined variable: \(name)"
    case let .invalidOperand(operatorValue):
      return "Invalid operand for operator: \(operatorValue)"
    case .invalidAssignmentTarget:
      return "Invalid assignment target"
    case let .notCallable(value):
      return "Value is not callable: \(value.displayValue)"
    case let .arityMismatch(expected, got):
      return "Arity mismatch: expected \(expected), got \(got)"
    case let .unimplemented(node):
      return "Eval is not implemented for: \(node)"
    case let .internalError(err):
      return "Internal error: \(err)"
    case .breakSignal:
      return "Break outside of loop"
    case .continueSignal:
      return "Continue the loop"
    case .returnSignal:
      return "Return outside of function"
    }
  }
}
