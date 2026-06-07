//
//  EvalRuntime+Value.swift
//  Vela
//
//  Created by Tao Xu on 6/2/26.
//

import Foundation

extension EvalRuntimeValue {
  var editorDisplayValue: String {
    switch self {
    case .object, .array:
      return jsonInspectDescription ?? displayValue
    default:
      return displayValue
    }
  }

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
    case let .array(array):
      return "[\(array.elements.map { $0.displayValue }.joined(separator: ", "))]"
    case let .klass(klass):
      return "<class \(klass.name)>"
    }
  }

  private var jsonInspectDescription: String? {
    guard JSONSerialization.isValidJSONObject(jsonInspectValue),
          let data = try? JSONSerialization.data(
            withJSONObject: jsonInspectValue,
            options: [.prettyPrinted, .sortedKeys]
          )
    else {
      return nil
    }

    return String(data: data, encoding: .utf8)
  }

  private var jsonInspectValue: Any {
    switch self {
    case let .object(object):
      if let klass = object.klass {
        return [
          "type": "object",
          "class": klass.name,
          "fields": object.fields.mapValues { $0.jsonInspectValue },
        ]
      }

      return object.fields.mapValues { $0.jsonInspectValue }
    case let .array(array):
      return array.elements.map { $0.jsonInspectValue }
    default:
      return jsonValue
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
        "expectedArgumentCount": jsonNullable(function.expectedArgumentCount),
      ]
    case let .object(object):
      return [
        "type": "object",
        "class": jsonNullable(object.klass?.name),
        "fields": object.fields.mapValues { $0.jsonValue },
      ]
    case let .array(array):
      return array.elements.map { $0.jsonValue }
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
    case let .bool(value):
      return value
    case let .int(value):
      return value > 0
    case let .double(value):
      return value > 0.0
    case .null:
      return false
    default:
      return true
    }
  }

  var toString: String? {
    switch self {
    case let .string(value):
      return value
    default:
      return nil
    }
  }

  var toObject: EvalRuntimeObject? {
    switch self {
    case let .object(obj):
      return obj
    default:
      return nil
    }
  }
}
