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
  @Test func evaluatesDefaultEditorExample() throws {
    var output: [String] = []
    let summary = try objectValue(eval(Parser.defaultExampleSource) {
      output.append($0)
    })

    #expect(output == ["point origin 25"])
    #expect(try numberValue(summary.fields["pointLength"] ?? .null) == 25)
    #expect(try stringValue(summary.fields["inheritedLabel"] ?? .null) == "origin")
    #expect(try stringValue(summary.fields["overriddenKind"] ?? .null) == "point")
    #expect(try boolValue(summary.fields["hasStatus"] ?? .null) == true)
    #expect(try numberValue(summary.fields["whileTotal"] ?? .null) == 8)
    #expect(try numberValue(summary.fields["forTotal"] ?? .null) == 7)
  }

  @Test func editorDisplayFormatsDefaultEditorSummary() throws {
    let display = try eval(Parser.defaultExampleSource).editorDisplayValue
    let summary = try jsonObject(display)

    #expect(summary["inheritedLabel"] as? String == "origin")
    #expect(summary["overriddenKind"] as? String == "point")
    #expect(summary["hasStatus"] as? Bool == true)
    #expect(summary["pointLength"] as? Double == 25)
    #expect(summary["numbers"] != nil)
  }

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

  @Test func evaluatesLogicalOperators() throws {
    #expect(try boolValue(eval("true && true;")) == true)
    #expect(try boolValue(eval("true && false;")) == false)
    #expect(try boolValue(eval("false && true;")) == false)
    #expect(try boolValue(eval("false || true;")) == true)
    #expect(try boolValue(eval("false || false;")) == false)
    #expect(try boolValue(eval("true || false;")) == true)
  }

  @Test func evaluatesLogicalPrecedence() throws {
    #expect(try boolValue(eval("true || false && false;")) == true)
    #expect(try boolValue(eval("false || true && false;")) == false)
    #expect(try boolValue(eval("(false || true) && false;")) == false)
  }

  @Test func shortCircuitsLogicalAnd() throws {
    #expect(try boolValue(eval("false && missing;")) == false)

    try expectRuntimeError(eval("true && missing;")) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "missing"
    }
  }

  @Test func shortCircuitsLogicalOr() throws {
    #expect(try boolValue(eval("true || missing;")) == true)

    try expectRuntimeError(eval("false || missing;")) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "missing"
    }
  }

  @Test func evaluatesEmptyDictionaryLiteral() throws {
    let object = try objectValue(eval("let object = {}; object;"))

    #expect(object.fields.isEmpty)
  }

  @Test func evaluatesDictionaryLiteral() throws {
    let result = try eval(#"""
    let name = "Vela";
    let object = { title: name, "count": 1 + 2, nested: { ok: true } };
    object;
    """#)

    let object = try objectValue(result)
    #expect(try stringValue(object.fields["title"] ?? .null) == "Vela")
    #expect(try numberValue(object.fields["count"] ?? .null) == 3)

    let nested = try objectValue(object.fields["nested"] ?? .null)
    #expect(try boolValue(nested.fields["ok"] ?? .null) == true)
  }

  @Test func throwsInvalidOperandForUnsupportedDictionaryKey() throws {
    let expression = Expression.dictionaryLiteral(
      DictionaryLiteral(
        entries: [
          DictionaryEntry(
            key: .nullLiteral(NullLiteral(value: nil)),
            value: .numericLiteral(NumericLiteral(value: 1))
          ),
        ]
      )
    )

    try expectRuntimeError(Eval.evaluateExpression(expression, in: EvalEnvironment())) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == ":"
    }
  }

  @Test func evaluatesObjectDotMemberAccess() throws {
    let result = try eval(#"""
    let name = "wrong";
    let object = { name: "Vela", count: 3 };
    object.name;
    """#)

    #expect(try stringValue(result) == "Vela")
  }

  @Test func evaluatesNestedObjectDotMemberAccess() throws {
    let result = try eval(#"""
    let object = { nested: { title: "Vela" } };
    object.nested.title;
    """#)

    #expect(try stringValue(result) == "Vela")
  }

  @Test func evaluatesObjectComputedMemberAccess() throws {
    #expect(try stringValue(eval(#"let object = { name: "Vela" }; object["name"];"#)) == "Vela")
    #expect(try numberValue(eval(#"let key = "count"; let object = { count: 3 }; object[key];"#)) == 3)
  }

  @Test func evaluatesObjectDotMemberAssignment() throws {
    let result = try eval(#"""
    let object = {};
    object.name = "Vela";
    object.name;
    """#)

    #expect(try stringValue(result) == "Vela")
  }

  @Test func evaluatesObjectComputedMemberAssignment() throws {
    #expect(try stringValue(eval(#"let object = {}; object["name"] = "Vela"; object.name;"#)) == "Vela")
    #expect(try numberValue(eval(#"let key = "count"; let object = {}; object[key] = 3; object.count;"#)) == 3)
  }

  @Test func evaluatesObjectMemberCompoundAssignment() throws {
    #expect(try numberValue(eval("let object = { count: 1 }; object.count += 2; object.count;")) == 3)
    #expect(try stringValue(eval(#"let object = { name: "Ve" }; object.name += "la"; object.name;"#)) == "Vela")
    #expect(try numberValue(eval(#"let key = "count"; let object = { count: 6 }; object[key] /= 2; object.count;"#)) == 3)
  }

  @Test func missingObjectMemberEvaluatesToNull() throws {
    try requireNull(eval("let object = {}; object.name;"))
    try requireNull(eval(#"let object = {}; object["name"];"#))
  }

  @Test func throwsInvalidOperandForMemberAccessOnNonObject() throws {
    try expectRuntimeError(eval("let value = 1; value.name;")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "."
    }
  }

  @Test func throwsInvalidOperandForMemberAssignmentOnNonObject() throws {
    try expectRuntimeError(eval("let value = 1; value.name = 2;")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "."
    }
  }

  @Test func throwsInvalidOperandForNonStringComputedMemberKey() throws {
    try expectRuntimeError(eval("let object = {}; object[1];")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "[]"
    }
  }

  @Test func throwsInvalidOperandForNonStringComputedMemberAssignmentKey() throws {
    try expectRuntimeError(eval("let object = {}; object[1] = 2;")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "[]"
    }
  }

  @Test func evaluatesEmptyArrayLiteral() throws {
    let array = try arrayValue(eval("[];"))

    #expect(array.isEmpty)
  }

  @Test func evaluatesArrayLiteral() throws {
    let result = try eval(#"""
    let x = 1;
    [x, x + 1, "ok", true, null, { nested: false }];
    """#)

    let array = try arrayValue(result)
    #expect(array.count == 6)
    #expect(try numberValue(array[0]) == 1)
    #expect(try numberValue(array[1]) == 2)
    #expect(try stringValue(array[2]) == "ok")
    #expect(try boolValue(array[3]) == true)
    try requireNull(array[4])

    let object = try objectValue(array[5])
    #expect(try boolValue(object.fields["nested"] ?? .null) == false)
  }

  @Test func evaluatesArrayIndexAccess() throws {
    #expect(try stringValue(eval(#"let values = ["a", "b"]; values[0];"#)) == "a")
    #expect(try stringValue(eval(#"let index = 1; let values = ["a", "b"]; values[index];"#)) == "b")
  }

  @Test func missingArrayIndexEvaluatesToNull() throws {
    try requireNull(eval(#"let values = ["a"]; values[1];"#))
    try requireNull(eval(#"let values = ["a"]; values[-1];"#))
  }

  @Test func throwsInvalidOperandForNonIntegerArrayIndex() throws {
    try expectRuntimeError(eval(#"let values = ["a"]; values["0"];"#)) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "[]"
    }
  }

  @Test func evaluatesArrayIndexAssignment() throws {
    #expect(try stringValue(eval(#"let values = ["a"]; values[0] = "b"; values[0];"#)) == "b")
    #expect(try numberValue(eval(#"let index = 1; let values = [1, 2]; values[index] = 3; values[1];"#)) == 3)
  }

  @Test func evaluatesArrayIndexCompoundAssignment() throws {
    #expect(try numberValue(eval("let values = [1]; values[0] += 2; values[0];")) == 3)
    #expect(try stringValue(eval(#"let values = ["Ve"]; values[0] += "la"; values[0];"#)) == "Vela")
  }

  @Test func throwsInvalidOperandForOutOfBoundsArrayIndexAssignment() throws {
    try expectRuntimeError(eval("let values = [1]; values[1] = 2;")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "[]"
    }
  }

  @Test func arrayLiteralPropagatesElementErrors() throws {
    try expectRuntimeError(eval("[missing];")) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "missing"
    }
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

  @Test func evaluatesFunctionDeclarationAsNull() throws {
    try requireNull(eval("def noop() {}"))
  }

  @Test func functionDeclarationDefinesRuntimeFunction() throws {
    let function = try functionValue(eval("""
    def add(x, y) {
      return x + y;
    }
    add;
    """))

    #expect(function.name == "add")
    #expect(function.params == ["x", "y"])
    #expect(function.body.body.count == 1)
  }

  @Test func functionDeclarationCapturesDefinitionEnvironment() throws {
    let function = try functionValue(eval("""
    let x = 1;
    {
      let x = 2;
      def readX() {}
      readX;
    }
    """))

    #expect(try numberValue(function.closure.lookup("x")) == 2)
  }

  @Test func blockScopedFunctionDeclarationDoesNotLeak() throws {
    try expectRuntimeError(eval("""
    {
      def hidden() {}
    }
    hidden;
    """)) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "hidden"
    }
  }

  @Test func evaluatesFunctionCallWithReturnValue() throws {
    let result = try eval("""
    def add(x, y) {
      return x + y;
    }
    add(1, 2);
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func functionCallWithoutReturnEvaluatesToNull() throws {
    try requireNull(eval("""
    def noop() {
      let value = 1;
    }
    noop();
    """))
  }

  @Test func functionReturnWithoutValueEvaluatesToNull() throws {
    try requireNull(eval("""
    def noop() {
      return;
    }
    noop();
    """))
  }

  @Test func functionCallUsesLexicalScope() throws {
    let result = try eval("""
    let value = 10;
    def readValue() {
      return value;
    }
    {
      let value = 20;
      readValue();
    }
    """)

    #expect(try numberValue(result) == 10)
  }

  @Test func functionCallThrowsArityMismatch() throws {
    try expectRuntimeError(eval("""
    def add(x, y) {
      return x + y;
    }
    add(1);
    """)) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 2 && got == 1
    }
  }

  @Test func functionCallPropagatesArgumentErrors() throws {
    try expectRuntimeError(eval("""
    def id(value) {
      return value;
    }
    id(missing);
    """)) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "missing"
    }
  }

  @Test func functionCallPropagatesBodyErrors() throws {
    try expectRuntimeError(eval("""
    def fail() {
      return missing;
    }
    fail();
    """)) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "missing"
    }
  }

  @Test func evaluatesClassDeclaration() throws {
    let klass = try klassValue(eval("""
    class Point {}
    Point;
    """))

    #expect(klass.name == "Point")
    #expect(klass.superclass == nil)
    #expect(klass.methods.isEmpty)
  }

  @Test func classDeclarationStoresSuperclass() throws {
    let klass = try klassValue(eval("""
    class Shape {}
    class Point extends Shape {}
    Point;
    """))

    #expect(klass.name == "Point")
    #expect(klass.superclass?.name == "Shape")
  }

  @Test func classDeclarationStoresMethods() throws {
    let klass = try klassValue(eval("""
    class Point {
      def init(x) {}
    }
    Point;
    """))
    let initializer = try #require(klass.methods["init"])

    #expect(initializer.name == "init")
    #expect(initializer.params == ["x"])
  }

  @Test func evaluatesNewClassInstance() throws {
    let object = try objectValue(eval("""
    class Point {}
    new Point();
    """))

    #expect(object.klass?.name == "Point")
    #expect(object.fields.isEmpty)
  }

  @Test func newExpressionCallsInitWithSelfBoundToInstance() throws {
    let object = try objectValue(eval("""
    class Point {
      def init(x, y) {
        self.x = x;
        self.y = y;
      }
    }
    new Point(11, 12);
    """))

    #expect(object.klass?.name == "Point")
    #expect(try numberValue(object.fields["x"] ?? .null) == 11)
    #expect(try numberValue(object.fields["y"] ?? .null) == 12)
  }

  @Test func instanceMethodCallBindsSelfToReceiver() throws {
    let result = try eval("""
    class Point {
      def init(x, y) {
        self.x = x;
        self.y = y;
      }

      def sum() {
        return self.x + self.y;
      }
    }
    let point = new Point(11, 12);
    point.sum();
    """)

    #expect(try numberValue(result) == 23)
  }

  @Test func instanceMethodCanBeInheritedFromSuperclass() throws {
    let result = try eval("""
    class Shape {
      def name() {
        return "shape";
      }
    }

    class Point extends Shape {}

    let point = new Point();
    point.name();
    """)

    #expect(try stringValue(result) == "shape")
  }

  @Test func subclassMethodOverridesSuperclassMethod() throws {
    let result = try eval("""
    class Shape {
      def name() {
        return "shape";
      }
    }

    class Point extends Shape {
      def name() {
        return "point";
      }
    }

    let point = new Point();
    point.name();
    """)

    #expect(try stringValue(result) == "point")
  }

  @Test func inheritedMethodBindsSelfToSubclassInstance() throws {
    let result = try eval("""
    class Shape {
      def label() {
        return self.name;
      }
    }

    class Point extends Shape {
      def init(name) {
        self.name = name;
      }
    }

    let point = new Point("origin");
    point.label();
    """)

    #expect(try stringValue(result) == "origin")
  }

  @Test func newExpressionCanCallInheritedInit() throws {
    let object = try objectValue(eval("""
    class Shape {
      def init(name) {
        self.name = name;
      }
    }

    class Point extends Shape {}

    new Point("origin");
    """))

    #expect(object.klass?.name == "Point")
    #expect(try stringValue(object.fields["name"] ?? .null) == "origin")
  }

  @Test func instanceFieldTakesPrecedenceOverClassMethod() throws {
    let result = try eval("""
    class Point {
      def value() {
        return 1;
      }
    }
    let point = new Point();
    point.value = 2;
    point.value;
    """)

    #expect(try numberValue(result) == 2)
  }

  @Test func classDeclarationThrowsInvalidOperandForNonClassSuperclass() throws {
    try expectRuntimeError(eval("""
    let Shape = 1;
    class Point extends Shape {}
    """)) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "extends"
    }
  }

  @Test func newExpressionThrowsNotCallableForNonClass() throws {
    try expectRuntimeError(eval("new 1();")) { error in
      guard case .notCallable = error else {
        return false
      }

      return true
    }
  }

  @Test func newExpressionThrowsArityMismatchForArgumentsWithoutInit() throws {
    try expectRuntimeError(eval("""
    class Point {}
    new Point(1);
    """)) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 0 && got == 1
    }
  }

  @Test func newExpressionThrowsInitArityMismatch() throws {
    try expectRuntimeError(eval("""
    class Point {
      def init(x, y) {}
    }
    new Point(1);
    """)) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 2 && got == 1
    }
  }

  @Test func selfOutsideBoundMethodThrowsUndefinedVariable() throws {
    try expectRuntimeError(eval("self;")) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "self"
    }
  }

  @Test func evaluatesNativePrintCall() throws {
    var output: [String] = []

    let result = try eval(
      #"""
      print("Vela", 1 + 2, true, null);
      """#,
      output: { output.append($0) }
    )

    try requireNull(result)
    #expect(output == ["Vela 3 true null"])
  }

  @Test func evaluatesNativeLenCall() throws {
    #expect(try numberValue(eval(#"len("Vela");"#)) == 4)
    #expect(try numberValue(eval("len([1, 2, 3]);")) == 3)
    #expect(try numberValue(eval("len({ name: \"Vela\", count: 1 });")) == 2)
  }

  @Test func nativeLenThrowsArityMismatch() throws {
    try expectRuntimeError(eval("len();")) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 1 && got == 0
    }
  }

  @Test func nativeLenThrowsInvalidOperandForUnsupportedValues() throws {
    try expectRuntimeError(eval("len(1);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "len"
    }
  }

  @Test func evaluatesNativeTypeCall() throws {
    #expect(try stringValue(eval("type(1);")) == "int")
    #expect(try stringValue(eval("type(5 / 2);")) == "double")
    #expect(try stringValue(eval(#"type("Vela");"#)) == "string")
    #expect(try stringValue(eval("type(true);")) == "bool")
    #expect(try stringValue(eval("type(null);")) == "null")
    #expect(try stringValue(eval("type([1, 2]);")) == "array")
    #expect(try stringValue(eval("type({ name: \"Vela\" });")) == "object")
    #expect(try stringValue(eval("def add(x, y) { return x + y; } type(add);")) == "function")
    #expect(try stringValue(eval("type(print);")) == "nativeFunction")
  }

  @Test func nativeTypeThrowsArityMismatch() throws {
    try expectRuntimeError(eval("type();")) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 1 && got == 0
    }
  }

  @Test func evaluatesNativeStrCall() throws {
    #expect(try stringValue(eval("str(1);")) == "1")
    #expect(try stringValue(eval("str(5 / 2);")) == "2.5")
    #expect(try stringValue(eval(#"str("Vela");"#)) == "Vela")
    #expect(try stringValue(eval("str(true);")) == "true")
    #expect(try stringValue(eval("str(null);")) == "null")
    #expect(try stringValue(eval(#"str([1, "two", false]);"#)) == "[1, two, false]")
    #expect(try stringValue(eval("str({ name: \"Vela\" });")) == "<object>")
  }

  @Test func nativeStrThrowsArityMismatch() throws {
    try expectRuntimeError(eval("str();")) { error in
      guard case let .arityMismatch(expected, got) = error else {
        return false
      }

      return expected == 1 && got == 0
    }
  }

  @Test func evaluatesNativeAppendCall() throws {
    let array = try arrayValue(eval("""
    let values = [];
    append(values, 1);
    append(values, "two");
    values;
    """))

    #expect(array.count == 2)
    #expect(try numberValue(array[0]) == 1)
    #expect(try stringValue(array[1]) == "two")
  }

  @Test func nativeAppendReturnsMutatedArray() throws {
    let result = try eval("""
    let values = [];
    let returned = append(values, 1);
    returned[0];
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func nativeAppendThrowsInvalidOperandForNonArray() throws {
    try expectRuntimeError(eval("append(1, 2);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "append"
    }
  }

  @Test func evaluatesNativePopCall() throws {
    let result = try eval("""
    let values = [1, 2];
    let last = pop(values);
    last + len(values);
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func nativePopOnEmptyArrayReturnsNull() throws {
    try requireNull(eval("pop([]);"))
  }

  @Test func nativePopThrowsInvalidOperandForNonArray() throws {
    try expectRuntimeError(eval("pop(1);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "pop"
    }
  }

  @Test func evaluatesNativeDictionaryKeysCall() throws {
    let keys = try arrayValue(eval("keys({ b: 2, a: 1 });"))

    #expect(keys.count == 2)
    #expect(try stringValue(keys[0]) == "a")
    #expect(try stringValue(keys[1]) == "b")
  }

  @Test func evaluatesNativeDictionaryHasCall() throws {
    #expect(try boolValue(eval(#"has({ name: "Vela" }, "name");"#)) == true)
    #expect(try boolValue(eval(#"has({ name: "Vela" }, "missing");"#)) == false)
  }

  @Test func evaluatesNativeDictionarySetCall() throws {
    let result = try eval("""
    let object = {};
    set(object, "name", "Vela");
    object.name;
    """)

    #expect(try stringValue(result) == "Vela")
  }

  @Test func nativeDictionarySetReturnsMutatedObject() throws {
    let result = try eval("""
    let object = {};
    let returned = set(object, "count", 2);
    returned.count;
    """)

    #expect(try numberValue(result) == 2)
  }

  @Test func nativeDictionaryBuiltinsThrowInvalidOperandForUnsupportedValues() throws {
    try expectRuntimeError(eval("keys(1);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "keys"
    }

    try expectRuntimeError(eval("has({}, 1);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "has"
    }

    try expectRuntimeError(eval("set({}, 1, 2);")) { error in
      guard case let .invalidOperand(operatorValue) = error else {
        return false
      }

      return operatorValue == "set"
    }
  }

  @Test func globalEnvironmentClearRestoresNativeBuiltins() throws {
    Eval.globalEnv.clear()

    let printFunction = try nativeFunctionValue(Eval.globalEnv.lookup("print"))
    let lenFunction = try nativeFunctionValue(Eval.globalEnv.lookup("len"))
    let typeFunction = try nativeFunctionValue(Eval.globalEnv.lookup("type"))
    let strFunction = try nativeFunctionValue(Eval.globalEnv.lookup("str"))
    let appendFunction = try nativeFunctionValue(Eval.globalEnv.lookup("append"))
    let popFunction = try nativeFunctionValue(Eval.globalEnv.lookup("pop"))
    let keysFunction = try nativeFunctionValue(Eval.globalEnv.lookup("keys"))
    let hasFunction = try nativeFunctionValue(Eval.globalEnv.lookup("has"))
    let setFunction = try nativeFunctionValue(Eval.globalEnv.lookup("set"))

    #expect(printFunction.name == "print")
    #expect(printFunction.expectedArgumentCount == nil)
    #expect(lenFunction.name == "len")
    #expect(lenFunction.expectedArgumentCount == 1)
    #expect(typeFunction.name == "type")
    #expect(typeFunction.expectedArgumentCount == 1)
    #expect(strFunction.name == "str")
    #expect(strFunction.expectedArgumentCount == 1)
    #expect(appendFunction.name == "append")
    #expect(appendFunction.expectedArgumentCount == 2)
    #expect(popFunction.name == "pop")
    #expect(popFunction.expectedArgumentCount == 1)
    #expect(keysFunction.name == "keys")
    #expect(keysFunction.expectedArgumentCount == 1)
    #expect(hasFunction.name == "has")
    #expect(hasFunction.expectedArgumentCount == 2)
    #expect(setFunction.name == "set")
    #expect(setFunction.expectedArgumentCount == 3)
  }

  @Test func throwsNotCallableForCallOnNonFunction() throws {
    try expectRuntimeError(eval("1();")) { error in
      guard case .notCallable = error else {
        return false
      }

      return true
    }
  }

  @Test func returnOutsideFunctionThrowsReturnSignal() throws {
    try expectRuntimeError(eval("return 1;")) { error in
      guard case let .returnSignal(value) = error else {
        return false
      }

      return (try? numberValue(value)) == 1
    }
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
    #expect(json["builtins"] != nil)
    #expect(firstChild["builtins"] == nil)
  }

  @Test func environmentJsonSeparatesBuiltinsFromValues() throws {
    let env = EvalEnvironment()
    let parser = Parser()
    let program = try #require(try parser.parse("""
    let x = 1;
    let p = print;
    """))

    _ = try Eval.eval(program, in: env)

    let json = try jsonObject(env.jsonDescription)
    let values = try dictionaryValue(json["values"])
    let builtins = try arrayValue(json["builtins"])
    let printAlias = try dictionaryValue(values["p"])

    #expect(values["x"] as? Double == 1)
    #expect(values["print"] == nil)
    #expect(builtins.compactMap { $0 as? String }.contains("print"))
    #expect(printAlias["type"] as? String == "nativeFunction")
  }

  @Test func environmentJsonIncludesObjectClassName() throws {
    let env = EvalEnvironment()
    let parser = Parser()
    let program = try #require(try parser.parse("""
    class Point {}
    let point = new Point();
    """))

    _ = try Eval.eval(program, in: env)

    let json = try jsonObject(env.jsonDescription)
    let values = try dictionaryValue(json["values"])
    let point = try dictionaryValue(values["point"])

    #expect(point["type"] as? String == "object")
    #expect(point["class"] as? String == "Point")
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

  @Test func evaluatesWhileStatement() throws {
    let result = try eval("""
    let i = 0;
    let total = 0;
    while (i < 3) {
      total += i;
      i += 1;
    }
    total;
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func whileStatementSkipsBodyWhenConditionIsFalse() throws {
    let result = try eval("""
    let value = 1;
    while (false) {
      value = 2;
    }
    value;
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func evaluatesDoWhileStatement() throws {
    let result = try eval("""
    let value = 1;
    do {
      value += 1;
    } while (value < 3);
    value;
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func doWhileStatementRunsBodyBeforeCheckingCondition() throws {
    let result = try eval("""
    let value = 1;
    do {
      value = 2;
    } while (false);
    value;
    """)

    #expect(try numberValue(result) == 2)
  }

  @Test func evaluatesForStatementWithVariableInitializer() throws {
    let result = try eval("""
    let total = 0;
    for (let i = 0; i < 3; i += 1) {
      total += i;
    }
    total;
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func evaluatesForStatementWithExpressionInitializer() throws {
    let result = try eval("""
    let i = 0;
    for (i = 1; i < 4; i += 1) {}
    i;
    """)

    #expect(try numberValue(result) == 4)
  }

  @Test func evaluatesForStatementWithOmittedInitializerAndUpdate() throws {
    let result = try eval("""
    let i = 0;
    for (; i < 3;) {
      i += 1;
    }
    i;
    """)

    #expect(try numberValue(result) == 3)
  }

  @Test func forStatementSkipsBodyWhenConditionIsFalse() throws {
    let result = try eval("""
    let value = 1;
    for (let i = 0; i < 0; i += 1) {
      value = 2;
    }
    value;
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func forStatementVariableInitializerDoesNotLeak() throws {
    try expectRuntimeError(eval("""
    for (let i = 0; i < 1; i += 1) {}
    i;
    """)) { error in
      guard case let .undefinedVariable(name) = error else {
        return false
      }

      return name == "i"
    }
  }

  @Test func breakExitsWhileStatement() throws {
    let result = try eval("""
    let i = 0;
    while (true) {
      i += 1;
      break;
      i = 100;
    }
    i;
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func breakExitsDoWhileStatement() throws {
    let result = try eval("""
    let i = 0;
    do {
      i += 1;
      break;
    } while (true);
    i;
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func breakExitsForStatement() throws {
    let result = try eval("""
    let i = 0;
    for (;;) {
      i += 1;
      break;
    }
    i;
    """)

    #expect(try numberValue(result) == 1)
  }

  @Test func breakInsideIfExitsNearestLoop() throws {
    let result = try eval("""
    let i = 0;
    while (true) {
      if (i == 2) {
        break;
      }
      i += 1;
    }
    i;
    """)

    #expect(try numberValue(result) == 2)
  }

  @Test func breakOutsideLoopThrowsBreakSignal() throws {
    try expectRuntimeError(eval("break;")) { error in
      guard case .breakSignal = error else {
        return false
      }

      return true
    }
  }

  @Test func continueSkipsRestOfWhileIteration() throws {
    let result = try eval("""
    let i = 0;
    let total = 0;
    while (i < 4) {
      i += 1;
      if (i == 2) {
        continue;
      }
      total += i;
    }
    total;
    """)

    #expect(try numberValue(result) == 8)
  }

  @Test func continueSkipsRestOfDoWhileIteration() throws {
    let result = try eval("""
    let i = 0;
    let total = 0;
    do {
      i += 1;
      if (i == 2) {
        continue;
      }
      total += i;
    } while (i < 4);
    total;
    """)

    #expect(try numberValue(result) == 8)
  }

  @Test func continueInForStatementRunsUpdateExpression() throws {
    let result = try eval("""
    let total = 0;
    for (let i = 0; i < 4; i += 1) {
      if (i == 2) {
        continue;
      }
      total += i;
    }
    total;
    """)

    #expect(try numberValue(result) == 4)
  }

  @Test func continueOutsideLoopThrowsContinueSignal() throws {
    try expectRuntimeError(eval("continue;")) { error in
      guard case .continueSignal = error else {
        return false
      }

      return true
    }
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

    try expectRuntimeError(Eval.evaluateExpression(expression, in: EvalEnvironment())) { error in
      guard case .invalidAssignmentTarget = error else {
        return false
      }

      return true
    }
  }
}

private func eval(
  _ source: String,
  output: @escaping (String) -> Void = { _ in }
) throws -> EvalRuntimeValue {
  let parser = Parser()
  guard let program = try parser.parse(source) else {
    print(parser.results)
    throw EvalTestFailure()
  }
  return try Eval.eval(program, in: EvalEnvironment(builtins: .standard(output: output)))
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

private func objectValue(_ value: EvalRuntimeValue) throws -> EvalRuntimeObject {
  guard case let .object(object) = value else {
    Issue.record("Expected object")
    throw EvalTestFailure()
  }

  return object
}

private func arrayValue(_ value: EvalRuntimeValue) throws -> [EvalRuntimeValue] {
  guard case let .array(array) = value else {
    Issue.record("Expected array")
    throw EvalTestFailure()
  }

  return array.elements
}

private func functionValue(_ value: EvalRuntimeValue) throws -> EvalRuntimeFunction {
  guard case let .function(function) = value else {
    Issue.record("Expected function")
    throw EvalTestFailure()
  }

  return function
}

private func nativeFunctionValue(_ value: EvalRuntimeValue) throws -> NativeFunction {
  guard case let .nativeFunction(function) = value else {
    Issue.record("Expected native function")
    throw EvalTestFailure()
  }

  return function
}

private func klassValue(_ value: EvalRuntimeValue) throws -> EvalRuntimeClass {
  guard case let .klass(klass) = value else {
    Issue.record("Expected class")
    throw EvalTestFailure()
  }

  return klass
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
