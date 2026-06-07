//
//  Eval+Statements.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//
import Foundation

extension Eval {
  static func execute(_ statement: Statement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Dispatch by AST statement kind.
    // 2. Execute normal statements and return their runtime result.
    // 3. Turn control-flow statements into runtime signals.
    switch statement {
    case .Empty:
      return .null
    case let .Block(block):
      return try Eval.evaluateBlockStatement(block, in: env)
    case let .Expression(expr):
      return try Eval.evaluateExpression(expr.value, in: env)
    case let .Variable(stmt):
      return try Eval.evaluateVariableSetatement(stmt, in: env)
    case let .If(stmt):
      return try Eval.evaluateIfStatement(stmt, in: env)
    case let .Iteration(stmt):
      return try Eval.evaluateLoopStatement(stmt, in: env)
    case .Break:
      throw .breakSignal
    case .Continue:
      throw .continueSignal
    case let .Return(stmt):
      let value = try Eval.evaluateReturnStatement(stmt, in: env)
      throw .returnSignal(value)
    case let .Function(stmt):
      return try Eval.evaluateFunctionDeclarationStatement(stmt, in: env)
    case let .ClassDeclaration(stmt):
      return try Eval.evaluateClassDeclarationStatement(stmt, in: env)
    }
  }
}

// MARK: Block Statement

extension Eval {
  static func evaluateBlockStatement(_ stmt: BlockStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Create a child environment for block-local bindings.
    // 2. Execute statements in order inside that environment.
    // 3. Return the last statement result, or null for an empty block.
    let blockEnv = EvalEnvironment(parent: env)
    var result: EvalRuntimeValue = .null

    for statement in stmt.body {
      result = try execute(statement, in: blockEnv)
    }

    return result
  }
}

// MARK: Variable Statement

extension Eval {
  static func evaluateVariableSetatement(_ stmt: VariableStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Visit each declaration from left to right.
    // 2. Evaluate the initializer when present, otherwise use null.
    // 3. Define each binding in the current environment.
    for declaration in stmt.declarations {
      let value: EvalRuntimeValue
      if let initializer = declaration.initializer {
        value = try evaluateExpression(initializer, in: env)
      } else {
        value = .null
      }
      env.define(declaration.id, value)
    }
    return .null
  }
}

// MARK: If Statement

extension Eval {
  static func evaluateIfStatement(_ stmt: IFStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the condition.
    // 2. Execute the if body when truthy.
    // 3. Otherwise execute the else body if present, or return null.
    let condition = try evaluateExpression(stmt.condition, in: env)
    let isTrue = condition.isTruthy
    if isTrue {
      return try Eval.execute(.Block(stmt.ifBody), in: env)
    }
    if let elseBody = stmt.elseBody {
      return try Eval.execute(.Block(elseBody), in: env)
    }
    return .null
  }
}

// MARK: Loop Statement

extension Eval {
  static func evaluateLoopStatement(_ stmt: IterationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Dispatch to the concrete loop evaluator.
    // 2. Let the concrete evaluator handle break and continue signals.
    switch stmt {
    case let .whileLoop(whileStmt):
      return try evaluateWhileStatement(whileStmt, in: env)
    case let .forLoop(forStmt):
      return try evaluateForStatement(forStmt, in: env)
    }
  }

  static func evaluateWhileStatement(_ stmt: WhileIterationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. For do-while, execute the body once before checking the condition.
    // 2. For each loop pass, evaluate the condition before running the body.
    // 3. Convert break into loop exit and continue into the next condition check.
    // 4. Return the last completed body result, or null when no body completed.
    var result: EvalRuntimeValue = .null

    if stmt.isDoWhile {
      do {
        result = try Eval.execute(.Block(stmt.body), in: env)
      } catch .breakSignal {
        return result
      } catch .continueSignal {
        // no-op
      }
    }

    while try Eval.evaluateExpression(stmt.condition, in: env).isTruthy {
      do {
        result = try Eval.execute(.Block(stmt.body), in: env)
      } catch .breakSignal {
        break
      } catch .continueSignal {
        continue
      }
    }
    return result
  }

  static func evaluateForStatement(_ stmt: ForIterationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Create a loop-local environment.
    // 2. Evaluate the initializer once.
    // 3. Repeat while the condition is truthy, treating a missing condition as true.
    // 4. Execute the body, then run the update expression after normal completion or continue.
    // 5. Convert break into loop exit and return the last completed body result.

    // 1. Use a loop-local environment
    let loopEnv = EvalEnvironment(parent: env)

    // 2. Evaluate the start condition once
    if let initValStmt = stmt.start {
      switch initValStmt {
      case let .expression(expr):
        _ = try evaluateExpression(expr, in: loopEnv)
      case let .variable(varStmt):
        _ = try evaluateVariableSetatement(varStmt, in: loopEnv)
      }
    }

    // 3. for loop gets lowered to while loop
    var result: EvalRuntimeValue = .null
    while try evaluateForCondition(stmt, in: loopEnv) {
      do {
        result = try Eval.execute(.Block(stmt.body), in: loopEnv)
      } catch .breakSignal {
        break
      } catch .continueSignal {
        // no-op
      }
      try evaluateForUpdate(stmt, in: loopEnv)
    }
    return result
  }

  private static func evaluateForCondition(_ stmt: ForIterationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> Bool {
    // 1. Treat an omitted condition as true.
    // 2. Otherwise evaluate the condition and convert it to truthiness.
    guard let condition = stmt.cond else {
      return true
    }
    return try evaluateExpression(condition, in: env).isTruthy
  }

  private static func evaluateForUpdate(_ stmt: ForIterationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) {
    // 1. Skip work when the update expression is omitted.
    // 2. Otherwise evaluate the update for its side effect.
    if let updateExp = stmt.update {
      _ = try evaluateExpression(updateExp, in: env)
    }
  }
}

// MARK: Function Declaration Statement

extension Eval {
  static func evaluateFunctionDeclarationStatement(_ stmt: FunctionDeclarationStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Build a runtime function from the declaration metadata.
    // 2. Capture the current environment for lexical scope.
    // 3. Define the function name in the current environment.
    // 4. Return null because declarations do not produce a user value.
    let funcName = stmt.name
    env.define(funcName, .function(EvalRuntimeFunction(
      name: stmt.name,
      params: stmt.params,
      body: stmt.body,
      closure: env
    )))
    return .null
  }
}

// MARK: Return Statement

extension Eval {
  static func evaluateReturnStatement(_ stmt: ReturnStatement, in env: EvalEnvironment) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Evaluate the return expression when present.
    // 2. Use null for a bare return.
    // 3. The execute dispatcher wraps this value in returnSignal.
    if let value = stmt.value {
      return try evaluateExpression(value, in: env)
    } else {
      return .null
    }
  }
}

// MARK: Class Statement

extension Eval {
  static func evaluateClassDeclarationStatement(
    _ stmt: ClassDeclarationStatement,
    in env: EvalEnvironment
  ) throws(EvalRuntimeError) -> EvalRuntimeValue {
    // 1. Read the class name.
    // 2. Evaluate and validate the optional superclass.
    // 3. Collect methods declared directly on the class.
    // 4. Create a runtime class value.
    // 5. Define it in the current environment.
    // 6. Return null because declarations do not produce a user value.
    guard case let .identifierExpression(identifier) = stmt.id else {
      throw .internalError("Class declaration name must be an identifier")
    }

    let superclass = try evaluateSuperclass(stmt.superClass, in: env)

    // collect class methods
    var methods: [String: EvalRuntimeFunction] = [:]
    for stmt in stmt.body.body {
      guard case let .Function(functionStmt) = stmt else {
        throw .invalidOperand("class body")
      }
      methods[functionStmt.name] = EvalRuntimeFunction(
        name: functionStmt.name,
        params: functionStmt.params,
        body: functionStmt.body,
        closure: env
      )
    }

    let klass = EvalRuntimeClass(name: identifier.value, superclass: superclass, methods: methods)
    env.define(identifier.value, .klass(klass))

    return .null
  }

  private static func evaluateSuperclass(
    _ expression: Expression?,
    in env: EvalEnvironment
  ) throws(EvalRuntimeError) -> EvalRuntimeClass? {
    guard let expression else {
      return nil
    }

    let value = try evaluateExpression(expression, in: env)
    guard case let .klass(superclass) = value else {
      throw .invalidOperand("extends")
    }

    return superclass
  }
}
