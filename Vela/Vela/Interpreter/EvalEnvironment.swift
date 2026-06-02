//
//  Environment.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

final class EvalEnvironment {
  private var values: [String: EvalRuntimeValue] = [:]
     private let parent: EvalEnvironment?

     init(parent: EvalEnvironment? = nil) {
       self.parent = parent
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
}
