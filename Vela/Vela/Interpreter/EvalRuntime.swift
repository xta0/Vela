//
//  RuntimeValue.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

enum EvalRuntimeValue {
  case number(Double)
  case string(String)
  case bool(Bool)
  case null

  case function(EvalRuntimeFunction)
  case nativeFunction(NativeFunction)
  case object(EvalRuntimeObject)
  case klass(EvalRuntimeClass)
}

extension EvalRuntimeValue {
  var displayValue: String {
    switch self {
    case let .number(value):
      return value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(value)
    case let .string(value):
      return value
    case let .bool(value):
      return String(value)
    case .null:
      return "null"
    case let .function(function):
      return "<function \(function.name ?? "<anonymous>")>"
    case let .nativeFunction(function):
      return "<native function \(function.name)>"
    case .object:
      return "<object>"
    case let .klass(klass):
      return "<class \(klass.name)>"
    }
  }
}

struct EvalRuntimeFunction {
  let name: String?
  let params: [String]
  let body: BlockStatement
  let closure: EvalEnvironment
}

struct NativeFunction {
  let name: String
  let arity: Int?
  let call: ([EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue
}

final class EvalRuntimeObject {
  var fields: [String: EvalRuntimeValue] = [:]
}

final class EvalRuntimeClass {
   let name: String
   let superclass: EvalRuntimeClass?
   var methods: [String: EvalRuntimeFunction]

   init(
     name: String,
     superclass: EvalRuntimeClass? = nil,
     methods: [String: EvalRuntimeFunction] = [:]
   ) {
     self.name = name
     self.superclass = superclass
     self.methods = methods
   }
 }
