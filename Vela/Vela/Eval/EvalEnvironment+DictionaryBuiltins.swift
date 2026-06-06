//
//  EvalEnvironment+DictionaryBuiltins.swift
//  Vela
//
//  Created by Tao Xu on 6/6/26.
//

extension NativeFunction {
  static func keys() -> NativeFunction {
    NativeFunction(
      name: "keys",
      expectedArgumentCount: 1
    ) { (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      guard case let .object(object) = arguments[0] else {
        throw EvalRuntimeError.invalidOperand("keys")
      }

      let keys = object.fields.keys.sorted().map { EvalRuntimeValue.string($0) }
      return .array(EvalRuntimeArray(elements: keys))
    }
  }

  static func has() -> NativeFunction {
    NativeFunction(
      name: "has",
      expectedArgumentCount: 2
    ) { (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      guard case let .object(object) = arguments[0],
            case let .string(key) = arguments[1]
      else {
        throw EvalRuntimeError.invalidOperand("has")
      }

      return .bool(object.fields[key] != nil)
    }
  }

  static func set() -> NativeFunction {
    NativeFunction(
      name: "set",
      expectedArgumentCount: 3
    ) { (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      guard case let .object(object) = arguments[0],
            case let .string(key) = arguments[1]
      else {
        throw EvalRuntimeError.invalidOperand("set")
      }

      object.fields[key] = arguments[2]
      return .object(object)
    }
  }
}
