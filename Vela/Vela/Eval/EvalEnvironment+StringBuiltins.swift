//
//  EvalEnvironment+StringBuiltins.swift
//  Vela
//
//  Created by Tao Xu on 6/6/26.
//

extension NativeFunction {
  static func str() -> NativeFunction {
    NativeFunction(
      name: "str",
      expectedArgumentCount: 1
    ) { arguments in
      .string(arguments[0].displayValue)
    }
  }
}
