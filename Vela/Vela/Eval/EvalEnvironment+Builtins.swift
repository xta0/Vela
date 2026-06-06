//
//  EvalEnvironment+Builtins.swift
//  Vela
//
//  Created by Tao Xu on 6/6/26.
//

struct EvalBuiltins {
  private let functions: [NativeFunction]

  init(functions: [NativeFunction]) {
    self.functions = functions
  }

  static func standard(
    output: @escaping (String) -> Void = { Swift.print($0) }
  ) -> EvalBuiltins {
    EvalBuiltins(
      functions: [
        .print(output: output),
        .len(),
        .type(),
        .str(),
        .append(),
        .pop(),
        .keys(),
        .has(),
        .set(),
      ]
    )
  }

  func install(into env: EvalEnvironment) {
    for function in functions {
      env.define(function.name, .nativeFunction(function))
    }
  }
}

extension NativeFunction {
  static func print(output: @escaping (String) -> Void) -> NativeFunction {
    NativeFunction(
      name: "print",
      expectedArgumentCount: nil
    ) { arguments in
      output(arguments.map { $0.displayValue }.joined(separator: " "))
      return .null
    }
  }

  static func len() -> NativeFunction {
    NativeFunction(
      name: "len",
      expectedArgumentCount: 1
    ) { (arguments: [EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue in
      switch arguments[0] {
      case let .string(value):
        return .int(value.count)
      case let .array(array):
        return .int(array.elements.count)
      case let .object(object):
        return .int(object.fields.count)
      default:
        throw EvalRuntimeError.invalidOperand("len")
      }
    }
  }

  static func type() -> NativeFunction {
    NativeFunction(
      name: "type",
      expectedArgumentCount: 1
    ) { arguments in
      .string(arguments[0].typeName)
    }
  }
}

private extension EvalRuntimeValue {
  var typeName: String {
    switch self {
    case .int:
      return "int"
    case .double:
      return "double"
    case .string:
      return "string"
    case .bool:
      return "bool"
    case .null:
      return "null"
    case .function:
      return "function"
    case .nativeFunction:
      return "nativeFunction"
    case .object:
      return "object"
    case .array:
      return "array"
    case .klass:
      return "class"
    }
  }
}
