//
//  Environment.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

import Foundation

final class EvalEnvironment {
  private var values: [String: EvalRuntimeValue] = [:]
  private weak var parent: EvalEnvironment?
  private var children: [EvalEnvironment] = []

  init(parent: EvalEnvironment? = nil) {
    self.parent = parent
    parent?.addChild(self)
  }

  func define(_ name: String, _ value: EvalRuntimeValue) {
    values[name] = value
  }

  func lookup(_ name: String) throws(EvalRuntimeError) -> EvalRuntimeValue {
    if let value = values[name] {
      return value
    }

    if let parent {
      return try parent.lookup(name)
    }

    throw .undefinedVariable(name)
  }

  func assign(_ name: String, _ value: EvalRuntimeValue) throws(EvalRuntimeError) {
    if values.keys.contains(name) {
      values[name] = value
      return
    }

    if let parent {
      try parent.assign(name, value)
      return
    }

    throw .undefinedVariable(name)
  }

  func clear() {
    values.removeAll()
    children.removeAll()
  }

  var jsonDescription: String {
    do {
      let data = try JSONSerialization.data(
        withJSONObject: jsonValue,
        options: [.prettyPrinted, .sortedKeys]
      )

      return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
      return #"{"error":"Failed to encode environment"}"#
    }
  }

  private func addChild(_ child: EvalEnvironment) {
    children.append(child)
  }

  private var jsonValue: [String: Any] {
    [
      "values": values.mapValues { $0.jsonValue },
      "children": children.map { $0.jsonValue },
    ]
  }
}
