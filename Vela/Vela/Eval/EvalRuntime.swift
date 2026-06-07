//
//  EvalRuntime.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

import Foundation

enum EvalRuntimeValue {
  case int(Int)
  case double(Double)
  case string(String)
  case bool(Bool)
  case null

  case function(EvalRuntimeFunction)
  case nativeFunction(NativeFunction)
  case object(EvalRuntimeObject)
  case array(EvalRuntimeArray)
  case klass(EvalRuntimeClass)
}

struct EvalRuntimeFunction {
  let name: String?
  let params: [String]
  let body: BlockStatement
  let closure: EvalEnvironment
}

struct NativeFunction {
  let name: String
  let expectedArgumentCount: Int?
  let call: ([EvalRuntimeValue]) throws(EvalRuntimeError) -> EvalRuntimeValue
}

/// Plain dictionaries use nil klass; class instances keep their runtime class.
final class EvalRuntimeObject {
  let klass: EvalRuntimeClass?
  var fields: [String: EvalRuntimeValue] = [:]

  init(klass: EvalRuntimeClass? = nil) {
    self.klass = klass
  }
}

final class EvalRuntimeArray {
  var elements: [EvalRuntimeValue]

  init(elements: [EvalRuntimeValue] = []) {
    self.elements = elements
  }
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

  func findMethod(_ name: String) -> EvalRuntimeFunction? {
    if let method = methods[name] {
      return method
    }

    return superclass?.findMethod(name)
  }
}
