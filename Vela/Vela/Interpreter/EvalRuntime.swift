//
//  RuntimeValue.swift
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
