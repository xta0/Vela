//
//  Eval+If.swift
//  Vela
//
//  Created by Tao Xu on 6/2/26.
//

import Foundation

extension EvalRuntimeValue {
  var displayValue: String {
    switch self {
    case let .int(value):
      return String(value)
    case let .double(value):
      return String(value)
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

  var jsonValue: Any {
    switch self {
    case let .int(value):
      return value
    case let .double(value):
      return value
    case let .string(value):
      return value
    case let .bool(value):
      return value
    case .null:
      return NSNull()
    case let .function(function):
      return [
        "type": "function",
        "name": jsonNullable(function.name),
        "params": function.params,
      ]
    case let .nativeFunction(function):
      return [
        "type": "nativeFunction",
        "name": function.name,
        "arity": jsonNullable(function.arity),
      ]
    case let .object(object):
      return [
        "type": "object",
        "fields": object.fields.mapValues { $0.jsonValue },
      ]
    case let .klass(klass):
      return [
        "type": "class",
        "name": klass.name,
        "superclass": jsonNullable(klass.superclass?.name),
      ]
    }
  }

  private func jsonNullable(_ value: Any?) -> Any {
    guard let value else {
      return NSNull()
    }

    return value
  }
}

extension EvalRuntimeValue {
  var isTruthy: Bool {
    switch self {
    case .bool(let value):
      return value
    case .int(let value):
      return value > 0
    case .double(let value):
      return value > 0.0
    case .null:
      return false
    default:
      return true
    }
  }
}
