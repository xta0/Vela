//
//  Eval+Expressions.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

extension Eval {
  static func evaluateExpression(_ expression: Expression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Dispatch by AST expression kind.
    // 2. Evaluate leaf nodes directly.
    // 3. Delegate compound expressions to focused evaluators.
    switch expression {
    case let .numericLiteral(node):
      if node.value.truncatingRemainder(dividingBy: 1) == 0 {
        return .int(Int(node.value))
      }
      return .double(node.value)
    case let .stringLiteral(node):
      return .string(node.value)
    case let .booleanLiteral(node):
      return .bool(node.value)
    case .nullLiteral:
      return .null
    case let .binaryExpression(node):
      return try evaluateBinary(node, in: env)
    case let .identifierExpression(node):
      // identifier goes into env directly
      return try env.lookup(node.value)
    case let .assignmentExpression(node):
      return try evaluateAssignment(node, in: env)
    case let .unaryExpression(node):
      return try evaluateUnary(node, in: env)
    case let .logicalExpression(node):
      return try evaluateLogical(node, in: env)
    case let .dictionaryLiteral(node):
      return try evaluateDictionary(node, in: env)
    case let .arrayLiteral(node):
      return try evaluateArray(node, in: env)
    case let .memberExpression(node):
      return try evaluateMember(node, in: env)
    case let .funcCallExpression(node):
      return try evaluateFunctionCall(node, in: env)
    case let .newExpression(node):
      return try evaluateNewExpression(node, in: env)
    case .selfExpression:
      return try env.lookup("self")
    default:
      throw .unimplemented(expression.type)
    }
  }
}

// MARK: Unary Expression

extension Eval {
  static func evaluateUnary(_ node: UnaryExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the single operand first.
    // 2. Apply the unary operator to the runtime value.
    // 3. Reject values that do not support that operator.
    let argument = try evaluateExpression(node.argument, in: env)

    switch node.operatorValue {
    case "!":
      return .bool(!argument.isTruthy)
    case "-":
      switch argument {
      case let .int(value):
        return .int(-value)
      case let .double(value):
        return .double(-value)
      default:
        throw .invalidOperand("-")
      }
    default:
      throw .unimplemented(node.operatorValue)
    }
  }
}

// MARK: Binary Expression

extension Eval {
  static func evaluateBinary(_ node: BinaryExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the left operand.
    // 2. Evaluate the right operand.
    // 3. Apply the binary operator to both runtime values.
    let left = try evaluateExpression(node.left, in: env)
    let right = try evaluateExpression(node.right, in: env)
    return try applyBinary(node.operatorValue, left, right)
  }
}

// MARK: Logical Expression

extension Eval {
  static func evaluateLogical(_ node: LogicalExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the left operand.
    // 2. Short-circuit when the left value decides the result.
    // 3. Otherwise evaluate the right operand and apply the logical operator.
    let left = try evaluateExpression(node.left, in: env)

    switch node.operatorValue {
    case "&&":
      if !left.isTruthy {
        return .bool(false)
      }

      let right = try evaluateExpression(node.right, in: env)
      return try applyLogical(node.operatorValue, left, right)
    case "||":
      if left.isTruthy {
        return .bool(true)
      }

      let right = try evaluateExpression(node.right, in: env)
      return try applyLogical(node.operatorValue, left, right)
    default:
      throw .unimplemented("op: \(node.operatorValue)")
    }
  }
}

// MARK: Assignment Expression

extension Eval {
  private enum AssignmentTarget {
    case identifier(String)
    case member(EvalRuntimeObject, String)
    case arrayElement(EvalRuntimeArray, Int)
  }

  static func evaluateAssignment(_ node: AssignmentExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Resolve the left expression into an assignable target.
    // 2. Evaluate the right expression.
    // 3. For compound assignment, read the current target value and apply the operator.
    // 4. Store the final value back into the target and return it.
    let target = try assignmentTarget(node.left, in: env)
    var value = try evaluateExpression(node.right, in: env)

    switch node.operatorValue {
    case "=":
      try assign(value, to: target, in: env)
    case "+=":
      let current = try assignmentTargetValue(target, in: env)
      value = try applyBinary("+", current, value)
      try assign(value, to: target, in: env)
    case "-=":
      let current = try assignmentTargetValue(target, in: env)
      value = try applyBinary("-", current, value)
      try assign(value, to: target, in: env)
    case "*=":
      let current = try assignmentTargetValue(target, in: env)
      value = try applyBinary("*", current, value)
      try assign(value, to: target, in: env)
    case "/=":
      let current = try assignmentTargetValue(target, in: env)
      value = try applyBinary("/", current, value)
      try assign(value, to: target, in: env)
    default:
      throw .unimplemented(node.operatorValue)
    }

    return value
  }

  private static func assignmentTarget(_ expression: Expression, in env: EvalEnvironment) throws(EvalRuntimeError) -> AssignmentTarget {
    // 1. Accept identifiers as environment bindings.
    // 2. Accept member expressions as object fields or array elements.
    // 3. Reject all other expressions as invalid assignment targets.
    switch expression {
    case let .identifierExpression(identifier):
      return .identifier(identifier.value)
    case let .memberExpression(member):
      switch try resolveMember(member, in: env) {
      case let .object(object, key):
        return .member(object, key)
      case let .array(array, index):
        return .arrayElement(array, index)
      }
    default:
      throw .invalidAssignmentTarget
    }
  }

  private static func assignmentTargetValue(_ target: AssignmentTarget, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Read identifiers from the environment.
    // 2. Read object fields, defaulting missing fields to null.
    // 3. Read array elements through the same bounds behavior as indexing.
    switch target {
    case let .identifier(name):
      return try env.lookup(name)
    case let .member(object, key):
      return object.fields[key] ?? .null
    case let .arrayElement(array, index):
      return arrayElement(array, at: index)
    }
  }

  private static func assign(_ value: EvalRuntimeValue, to target: AssignmentTarget, in env: EvalEnvironment) throws(EvalRuntimeError) {
    // 1. Write identifiers through environment assignment.
    // 2. Write object fields directly on the runtime object.
    // 3. Write array elements after index validation.
    switch target {
    case let .identifier(name):
      try env.assign(name, value)
    case let .member(object, key):
      object.fields[key] = value
    case let .arrayElement(array, index):
      try assignArrayElement(value, to: array, at: index)
    }
  }
}

// MARK: Dictionary Literal

extension Eval {
  static func evaluateDictionary(_ node: DictionaryLiteral, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Create a mutable runtime object.
    // 2. Resolve each entry key.
    // 3. Evaluate each entry value and store it on the object.
    let object = EvalRuntimeObject()

    for entry in node.entries {
      let key = try dictionaryKey(entry.key)
      object.fields[key] = try evaluateExpression(entry.value, in: env)
    }

    return .object(object)
  }

  private static func dictionaryKey(_ expression: Expression) throws(EvalRuntimeError) -> String {
    // 1. Accept identifier keys as their source names.
    // 2. Accept string literal keys as their string values.
    // 3. Reject other key expressions for now.
    switch expression {
    case let .identifierExpression(node):
      return node.value
    case let .stringLiteral(node):
      return node.value
    default:
      throw .invalidOperand(":")
    }
  }
}

// MARK: Array Literal

extension Eval {
  static func evaluateArray(_ node: ArrayLiteral, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate elements from left to right.
    // 2. Preserve each runtime value in order.
    // 3. Wrap the values in a mutable runtime array.
    var elements: [EvalRuntimeValue] = []

    for element in node.elements {
      try elements.append(evaluateExpression(element, in: env))
    }

    return .array(EvalRuntimeArray(elements: elements))
  }
}

// MARK: Member Expression

extension Eval {
  private enum MemberReference {
    case object(EvalRuntimeObject, String) // x.name, x["name"]
    case array(EvalRuntimeArray, Int) // x[0], x[1]
  }

  static func evaluateMember(_ node: MemberExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Resolve the member expression into an object field or array element.
    // 2. Read object fields with missing fields as null.
    // 3. Read array elements with out-of-bounds elements as null.
    switch try resolveMember(node, in: env) {
    case let .object(object, key):
      return objectMemberValue(object, key)
    case let .array(array, index):
      return arrayElement(array, at: index)
    }
  }

  private static func resolveMember(_ node: MemberExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> MemberReference {
    // 1. Evaluate the receiver expression.
    // 2. Resolve object receivers to string property keys.
    // 3. Resolve array receivers to integer indexes.
    // 4. Reject member access on unsupported receiver values.
    let receiver = try evaluateExpression(node.object, in: env)
    switch receiver {
    case let .object(object):
      return try .object(object, objectMemberKey(node, in: env))
    case let .array(array):
      return try .array(array, arrayMemberIndex(node, in: env))
    default:
      throw .invalidOperand(node.computed ? "[]" : ".")
    }
  }

  // MARK: Dictionary/object

  private static func objectMemberKey(_ node: MemberExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> String {
    // 1. For computed access, evaluate the property expression and require a string.
    // 2. For dot access, use the property identifier name directly.
    if node.computed {
      // let x = "a"
      // y[x]
      let property = try evaluateExpression(node.property, in: env)
      guard let name = property.toString else {
        throw .invalidOperand("[]")
      }
      return name
    }

    // x.name
    guard case let .identifierExpression(property) = node.property else {
      throw .invalidOperand(".")
    }
    return property.value
  }

  private static func objectMemberValue(_ object: EvalRuntimeObject, _ key: String) -> EvalRuntimeValue {
    if let field = object.fields[key] {
      return field
    }

    if let method = object.klass?.findMethod(key) {
      return .function(bind(method, to: object))
    }

    return .null
  }

  // MARK: array

  private static func arrayMemberIndex(_ node: MemberExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> Int {
    // 1. Require computed access because arrays use [].
    // 2. Evaluate the index expression.
    // 3. Require the index to be an integer.
    guard node.computed else {
      throw .invalidOperand(".")
    }

    let property = try evaluateExpression(node.property, in: env)
    guard case let .int(index) = property else {
      throw .invalidOperand("[]")
    }
    return index
  }

  private static func arrayElement(_ array: EvalRuntimeArray, at index: Int) -> EvalRuntimeValue {
    // 1. Check whether the index exists.
    // 2. Return null for out-of-bounds reads.
    // 3. Otherwise return the stored element.
    guard array.elements.indices.contains(index) else {
      return .null
    }
    return array.elements[index]
  }

  private static func assignArrayElement(_ value: EvalRuntimeValue, to array: EvalRuntimeArray, at index: Int) throws(EvalRuntimeError) {
    // 1. Check whether the index exists.
    // 2. Reject out-of-bounds writes.
    // 3. Otherwise replace the stored element.
    guard array.elements.indices.contains(index) else {
      throw .invalidOperand("[]")
    }
    array.elements[index] = value
  }
}

// MARK: FunctionCall Expression

extension Eval {
  /**
   1. Add return propagation
   - Add case returnSignal(EvalRuntimeValue) to EvalRuntimeError.
   - In execute, handle .Return(stmt):

   let value = try stmt.value.map { try Eval.evaluateExpression($0, in: env) } ?? .null
   throw .returnSignal(value)

   2. Add call expression evaluation
   - In evaluateExpression, handle .funcCallExpression.
   - Evaluate callee.
   - Evaluate arguments left-to-right.

   3. Call runtime functions
   - For .function(function), check arguments.count == function.params.count.
   - Create call env:

   let callEnv = EvalEnvironment(parent: function.closure)
   - Bind params to args.
   - Execute body.
   - Catch .returnSignal(value) and return value.
   - If body finishes without return, return .null.

   4. Native functions
   - For .nativeFunction(native), check expectedArgumentCount if non-nil.
   - Call native.call(arguments).
   */
  static func evaluateFunctionCall(_ node: FuncCallExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the callee expression.
    // 2. Evaluate arguments from left to right.
    // 3. Dispatch to user-defined or native function call handling.
    // 4. Reject non-callable callee values.
    let callee = try evaluateExpression(node.callee, in: env)
    var args: [EvalRuntimeValue] = []
    for arg in node.arguments {
      try args.append(evaluateExpression(arg, in: env))
    }

    switch callee {
    case let .function(function):
      return try call(function, with: args)
    case let .nativeFunction(function):
      return try call(function, with: args)
    default:
      throw .notCallable(callee)
    }
  }

  private static func call(
    _ function: EvalRuntimeFunction,
    with args: [EvalRuntimeValue]
  ) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Validate argument count against parameter count.
    // 2. Create a call environment under the function's closure environment.
    // 3. Bind parameters to argument values.
    // 4. Execute the function body and convert returnSignal into the call result.
    guard function.params.count == args.count else {
      throw .arityMismatch(expected: function.params.count, got: args.count)
    }

    let callEnv = EvalEnvironment(parent: function.closure)
    for (param, arg) in zip(function.params, args) {
      callEnv.define(param, arg)
    }

    do {
      _ = try evaluateBlockStatement(function.body, in: callEnv)
      return .null
    } catch let .returnSignal(value) {
      return value
    } catch {
      throw error
    }
  }

  private static func call(
    _ function: NativeFunction,
    with args: [EvalRuntimeValue]
  ) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Validate argument count when the native function declares one.
    // 2. Delegate execution to the native Swift closure.
    if let expected = function.expectedArgumentCount, expected != args.count {
      throw .arityMismatch(expected: expected, got: args.count)
    }

    return try function.call(args)
  }
}

// MARK: `new` expression

extension Eval {
  static func evaluateNewExpression(_ node: NewExpression, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the callee, e.g. Point in new Point().
    // 2. Require it to be a class.
    // 3. Evaluate initializer arguments from left to right.
    // 4. Create an empty object instance linked to the class.
    // 5. Call init with self bound to the new object when the class defines one.

    let callee = try evaluateExpression(node.callee, in: env)
    guard case let .klass(clz) = callee else {
      throw .notCallable(callee)
    }

    var args: [EvalRuntimeValue] = []
    for arg in node.arguments {
      try args.append(evaluateExpression(arg, in: env))
    }

    let obj = EvalRuntimeObject(klass: clz)

    if let initializer = clz.findMethod("init") {
      let boundInitializer = bind(initializer, to: obj)
      _ = try call(boundInitializer, with: args)
    } else if !args.isEmpty {
      throw .arityMismatch(expected: 0, got: args.count)
    }

    return .object(obj)
  }

  /// Bind "self" to object in the method environment.
  private static func bind(_ method: EvalRuntimeFunction, to object: EvalRuntimeObject) -> EvalRuntimeFunction {
    let methodEnv = EvalEnvironment(parent: method.closure)
    methodEnv.define("self", .object(object))

    return EvalRuntimeFunction(
      name: method.name,
      params: method.params,
      body: method.body,
      closure: methodEnv
    )
  }
}
