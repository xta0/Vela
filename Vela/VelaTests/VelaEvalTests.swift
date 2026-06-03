//
//  VelaEvalTests.swift
//  VelaTests
//
//  Created by Tao Xu on 6/2/26.
//

import Foundation
import Testing
@testable import Vela

private struct EvalTestFailure: Error {}

struct VelaEvalTests {
  @Test func evaluatesNumericLiteral() throws {
    let result = try eval("42;")

    #expect(try numberValue(result) == 42)
  }

  @Test func evaluatesStringLiteral() throws {
    let result = try eval(#""hello";"#)

    #expect(try stringValue(result) == "hello")
  }

  @Test func evaluatesBooleanLiterals() throws {
    #expect(try boolValue(eval("true;")) == true)
    #expect(try boolValue(eval("false;")) == false)
  }

  @Test func evaluatesUnaryExpressions() throws {
    #expect(try numberValue(eval("-1;")) == -1)
    #expect(try numberValue(eval("-(1 + 2);")) == -3)
    #expect(try numberValue(eval("2 * -3;")) == -6)
    #expect(try boolValue(eval("!true;")) == false)
    #expect(try boolValue(eval("!false;")) == true)
  }

  @Test func evaluatesNullLiteral() throws {
    try requireNull(eval("null;"))
  }

  @Test func evaluatesBinaryExpressionWithLiteralOperands() throws {
    #expect(try numberValue(eval("1 + 2;")) == 3)
    #expect(try stringValue(eval(#""a" + "b";"#)) == "ab")
  }

  @Test func evaluatesNumericBinaryOperators() throws {
    #expect(try numberValue(eval("5 - 2;")) == 3)
    #expect(try numberValue(eval("3 * 4;")) == 12)
    #expect(try numberValue(eval("8 / 2;")) == 4)
  }

  @Test func evaluatesComparisonOperators() throws {
    #expect(try boolValue(eval("3 > 2;")) == true)
    #expect(try boolValue(eval("2 > 3;")) == false)
    #expect(try boolValue(eval("3 >= 3;")) == true)
    #expect(try boolValue(eval("2 < 3;")) == true)
    #expect(try boolValue(eval("3 < 2;")) == false)
    #expect(try boolValue(eval("3 <= 3;")) == true)
  }

  @Test func evaluatesEqualityOperators() throws {
    #expect(try boolValue(eval("1 == 1;")) == true)
    #expect(try boolValue(eval("1 == 2;")) == false)
    #expect(try boolValue(eval(#""a" == "a";"#)) == true)
    #expect(try boolValue(eval("true == false;")) == false)
    #expect(try boolValue(eval("null == null;")) == true)
    #expect(try boolValue(eval("1 == true;")) == false)

    #expect(try boolValue(eval("1 != 2;")) == true)
    #expect(try boolValue(eval("null != null;")) == false)
  }

  @Test func evaluatesVariableStatementWithInitializer() throws {
    let result = try eval("let x = 1 + 2; x;")

    #expect(try numberValue(result) == 3)
  }

  @Test func evaluatesVariableStatementWithoutInitializerAsNull() throws {
    let result = try eval("let x; x;")

    try requireNull(result)
  }

  @Test func evaluatesMultipleVariableDeclarations() throws {
    let result = try eval("let x = 1, y = 2; x + y;")

    #expect(try numberValue(result) == 3)
  }

  @Test func evaluatesAssignmentExpression() throws {
    let result = try eval("let x = 1; x = 4; x;")

    #expect(try numberValue(result) == 4)
  }

  @Test func evaluatesAssignmentToUnaryMinusExpression() throws {
    let result = try eval("let x = 1; x = -1; x;")

    #expect(try numberValue(result) == -1)
  }

  @Test func evaluatesCompoundAssignmentExpressions() throws {
    #expect(try numberValue(eval("let x = 1; x += 2; x;")) == 3)
    #expect(try numberValue(eval("let x = 5; x -= 2; x;")) == 3)
    #expect(try numberValue(eval("let x = 3; x *= 4; x;")) == 12)
    #expect(try numberValue(eval("let x = 8; x /= 2; x;")) == 4)
  }

  @Test func evaluatesBlockStatementResult() throws {
    let result = try eval("{ 1; 2; }")

    #expect(try numberValue(result) == 2)
  }

  @Test func blockStatementCreatesChildScope() throws {
    let result = try eval("let x = 1; { let x = 2; } x;")

    #expect(try numberValue(result) == 1)
  }

  @Test func blockStatementAssignsOuterScope() throws {
    let result = try eval("let x = 1; { x = x + 2; } x;")

    #expect(try numberValue(result) == 3)
  }

  @Test func emptyBlockStatementEvaluatesToNull() throws {
    try requireNull(eval("{}"))
  }

  @Test func environmentJsonIncludesChildScopes() throws {
    let env = EvalEnvironment()
    let parser = Parser()
    let program = try #require(try parser.parse("""
      let x = 1;
      {
        let y = x + 1;
        y += 1;
      }
      """))

    _ = try Eval.eval(program, in: env)

    let json = try jsonObject(env.jsonDescription)
    let values = try dictionaryValue(json["values"])
    let children = try arrayValue(json["children"])
    let firstChild = try dictionaryValue(children.first)
    let childValues = try dictionaryValue(firstChild["values"])

    #expect(values["x"] as? Double == 1)
    #expect(childValues["y"] as? Double == 3)
  }

  @Test func evaluatesIfThenBranch() throws {
    let result = try eval("""
      let x = 1;
      if (x > 0) {
        x += 1;
      }
      x;
      """)

    #expect(try numberValue(result) == 2)
  }

  @Test func skipsIfThenBranchWhenConditionIsFalse() throws {
    let result = try eval("""
      let x = 1;
      if (x > 1) {
        x += 1;
      }
      x;
      """)

    #expect(try numberValue(result) == 1)
  }

  @Test func evaluatesIfElseBranch() throws {
    let result = try eval("""
      let x = 1;
      if (x > 1) {
        x = 10;
      } else {
        x = 20;
      }
      x;
      """)

    #expect(try numberValue(result) == 20)
  }

  @Test func evaluatesIfStatementResultFromExecutedBlock() throws {
    #expect(try numberValue(eval("if (true) { 1; 2; } else { 3; }")) == 2)
    #expect(try numberValue(eval("if (false) { 1; } else { 3; 4; }")) == 4)
  }

  @Test func ifStatementCreatesBlockScope() throws {
    let result = try eval("""
      let x = 1;
      if (true) {
        let x = 10;
      }
      x;
      """)

    #expect(try numberValue(result) == 1)
  }

  @Test func throwsUndefinedVariable() throws {
    try expectRuntimeError(eval("x;")) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "x"
    }
  }

  @Test func throwsInvalidOperandForUnsupportedBinaryOperands() throws {
    try expectRuntimeError(eval(#""a" - "b";"#)) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "-"
    }
  }

  @Test func throwsInvalidOperandForUnsupportedUnaryOperand() throws {
    try expectRuntimeError(eval(#"-"a";"#)) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "-"
    }
  }

  @Test func throwsInvalidAssignmentTarget() throws {
    let expression = Expression.assignmentExpression(
      AssignmentExpression(
        operatorValue: "=",
        left: .numericLiteral(NumericLiteral(value: 1)),
        right: .numericLiteral(NumericLiteral(value: 2))
      )
    )

    try expectRuntimeError(try Eval.evaluateExpression(expression, in: EvalEnvironment())) { error in
      guard case .invalidAssignmentTarget = error else {
        return false
      }

      return true
    }
  }
}

private func eval(_ source: String) throws -> EvalRuntimeValue {
  let parser = Parser()
  let program = try #require(try parser.parse(source))
  return try Eval.eval(program, in: EvalEnvironment())
}

private func numberValue(_ value: EvalRuntimeValue) throws -> Double {
  switch value {
  case let .int(number):
    return Double(number)
  case let .double(number):
    return number
  default:
    Issue.record("Expected number")
    throw EvalTestFailure()
  }
}

private func stringValue(_ value: EvalRuntimeValue) throws -> String {
  guard case let .string(string) = value else {
    Issue.record("Expected string")
    throw EvalTestFailure()
  }

  return string
}

private func boolValue(_ value: EvalRuntimeValue) throws -> Bool {
  guard case let .bool(bool) = value else {
    Issue.record("Expected bool")
    throw EvalTestFailure()
  }

  return bool
}

private func requireNull(_ value: EvalRuntimeValue) throws {
  guard case .null = value else {
    Issue.record("Expected null")
    throw EvalTestFailure()
  }
}

private func jsonObject(_ text: String) throws -> [String: Any] {
  let data = try #require(text.data(using: .utf8))
  guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    Issue.record("Expected JSON object")
    throw EvalTestFailure()
  }

  return object
}

private func dictionaryValue(_ value: Any?) throws -> [String: Any] {
  guard let dictionary = value as? [String: Any] else {
    Issue.record("Expected dictionary")
    throw EvalTestFailure()
  }

  return dictionary
}

private func arrayValue(_ value: Any?) throws -> [Any] {
  guard let array = value as? [Any] else {
    Issue.record("Expected array")
    throw EvalTestFailure()
  }

  return array
}

private func expectRuntimeError(
  _ expression: @autoclosure () throws -> EvalRuntimeValue,
  matching predicate: (EvalRuntimeError) -> Bool
) throws {
  do {
    _ = try expression()
    Issue.record("Expected runtime error")
    throw EvalTestFailure()
  } catch let error as EvalRuntimeError {
    guard predicate(error) else {
      Issue.record("Unexpected runtime error: \(error)")
      throw EvalTestFailure()
    }
  }
}
