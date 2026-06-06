//
//  EvalEnvironment+ArrayBuiltins.swift
//  Vela
//
//  Created by Tao Xu on 6/6/26.
//

extension NativeFunction {
  static func append() -> NativeFunction {
    NativeFunction(
      name: "append",
      expectedArgumentCount: 2
    ) { (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      guard case let .array(array) = arguments[0] else {
        throw EvalRuntimeError.invalidOperand("append")
      }

      array.elements.append(arguments[1])
      return .array(array)
    }
  }

  static func pop() -> NativeFunction {
    NativeFunction(
      name: "pop",
      expectedArgumentCount: 1
    ) {
      (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      guard case let .array(array) = arguments[0] else {
        throw EvalRuntimeError.invalidOperand("pop")
      }
      let result = array.elements.popLast()
      return result ?? .null
    }
  }
}
