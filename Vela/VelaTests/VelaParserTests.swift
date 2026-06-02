//
//  VelaParserTests.swift
//  Vela
//
//  Created by Tao Xu on 6/1/26.
//

import Testing
@testable import Vela

struct VelaParserTests {
  @Test func parsesNumericLiteralExpressionStatement() throws {
    let program = try parseProgram("42;")

    #expect(program.body.count == 1)
    let expression = try expressionStatementValue(program.body[0])

    guard case let .numericLiteral(node) = expression else {
      Issue.record("Expected NumericLiteral expression")
      return
    }

    #expect(node.value == 42)
  }

  @Test func parsesDoubleQuotedStringLiteralExpressionStatement() throws {
    let program = try parseProgram(#""hello";"#)

    #expect(program.body.count == 1)
    let expression = try expressionStatementValue(program.body[0])

    guard case let .stringLiteral(node) = expression else {
      Issue.record("Expected StringLiteral expression")
      return
    }

    #expect(node.value == "hello")
  }

  @Test func parsesSingleQuotedStringLiteralExpressionStatement() throws {
    let program = try parseProgram("'hello';")

    #expect(program.body.count == 1)
    let expression = try expressionStatementValue(program.body[0])

    guard case let .stringLiteral(node) = expression else {
      Issue.record("Expected StringLiteral expression")
      return
    }

    #expect(node.value == "hello")
  }

  @Test func parsesTrueLiteralExpressionStatement() throws {
    let program = try parseProgram("true;")

    #expect(program.body.count == 1)
    #expect(try booleanValue(expressionStatementValue(program.body[0])) == true)
  }

  @Test func parsesFalseLiteralExpressionStatement() throws {
    let program = try parseProgram("false;")

    #expect(program.body.count == 1)
    #expect(try booleanValue(expressionStatementValue(program.body[0])) == false)
  }

  @Test func parsesNullLiteralExpressionStatement() throws {
    let program = try parseProgram("null;")

    #expect(program.body.count == 1)
    try requireNullLiteral(expressionStatementValue(program.body[0]))
  }

  @Test func parsesEmptyStatement() throws {
    let program = try parseProgram(";")

    #expect(program.body.count == 1)
    guard case .Empty = program.body[0] else {
      Issue.record("Expected EmptyStatement")
      return
    }
  }

  @Test func parsesMultipleStatementTypes() throws {
    let program = try parseProgram(#"42; "hello"; ;"#)

    #expect(program.body.count == 3)
    #expect(try numericValue(program.body[0]) == 42)
    #expect(try stringValue(program.body[1]) == "hello")

    guard case .Empty = program.body[2] else {
      Issue.record("Expected third statement to be EmptyStatement")
      return
    }
  }

  @Test func parsesVariableStatementWithInitializer() throws {
    let program = try parseProgram("let x = 1;")

    #expect(program.body.count == 1)
    let variable = try variableStatement(program.body[0])

    #expect(variable.declarations.count == 1)
    let declaration = variable.declarations[0]
    #expect(declaration.id == "x")
    #expect(try numericValue(#require(declaration.initializer)) == 1)
  }

  @Test func parsesVariableStatementWithoutInitializer() throws {
    let program = try parseProgram("let x;")

    #expect(program.body.count == 1)
    let variable = try variableStatement(program.body[0])

    #expect(variable.declarations.count == 1)
    let declaration = variable.declarations[0]
    #expect(declaration.id == "x")
    #expect(declaration.initializer == nil)
  }

  @Test func parsesVariableStatementWithMultipleDeclarations() throws {
    let program = try parseProgram("let x = 1, y = 2;")

    #expect(program.body.count == 1)
    let variable = try variableStatement(program.body[0])

    #expect(variable.declarations.count == 2)
    #expect(variable.declarations[0].id == "x")
    #expect(try numericValue(#require(variable.declarations[0].initializer)) == 1)
    #expect(variable.declarations[1].id == "y")
    #expect(try numericValue(#require(variable.declarations[1].initializer)) == 2)
  }

  @Test func parsesVariableStatementWithAssignmentInitializer() throws {
    let program = try parseProgram("let foo = bar = 42;")

    #expect(program.body.count == 1)
    let variable = try variableStatement(program.body[0])

    #expect(variable.declarations.count == 1)
    let declaration = variable.declarations[0]
    #expect(declaration.id == "foo")

    let initializer = try assignmentExpression(#require(declaration.initializer))
    #expect(initializer.operatorValue == "=")
    #expect(try identifierValue(initializer.left) == "bar")
    #expect(try numericValue(initializer.right) == 42)
  }

  @Test func parsesFunctionDeclarationWithoutParameters() throws {
    let program = try parseProgram("def noop() {}")

    #expect(program.body.count == 1)
    let function = try functionDeclarationStatement(program.body[0])

    #expect(function.name == "noop")
    #expect(function.params.isEmpty)
    #expect(function.body.body.isEmpty)
  }

  @Test func parsesFunctionDeclarationWithParametersAndReturn() throws {
    let program = try parseProgram("def add(x, y) { return x + y; }")

    #expect(program.body.count == 1)
    let function = try functionDeclarationStatement(program.body[0])

    #expect(function.name == "add")
    #expect(function.params == ["x", "y"])
    #expect(function.body.body.count == 1)

    let returnStatement = try returnStatement(function.body.body[0])
    let returnedValue = try #require(returnStatement.value)
    let binary = try binaryExpression(returnedValue)
    #expect(binary.operatorValue == "+")
    #expect(try identifierValue(binary.left) == "x")
    #expect(try identifierValue(binary.right) == "y")
  }

  @Test func parsesReturnStatementWithoutValue() throws {
    let program = try parseProgram("return;")

    #expect(program.body.count == 1)
    let statement = try returnStatement(program.body[0])
    #expect(statement.value == nil)
  }

  @Test func parsesKeywordPrefixAsIdentifier() throws {
    let program = try parseProgram("returnValue;")

    #expect(program.body.count == 1)
    #expect(try identifierValue(expressionStatementValue(program.body[0])) == "returnValue")
  }

  @Test func parsesEmptyBlockStatement() throws {
    let program = try parseProgram("{}")

    #expect(program.body.count == 1)
    let block = try blockStatement(program.body[0])
    #expect(block.body.isEmpty)
  }

  @Test func parsesBlockStatementBody() throws {
    let program = try parseProgram(#"{ 1; "two"; ; }"#)

    #expect(program.body.count == 1)
    let block = try blockStatement(program.body[0])

    #expect(block.body.count == 3)
    #expect(try numericValue(block.body[0]) == 1)
    #expect(try stringValue(block.body[1]) == "two")

    guard case .Empty = block.body[2] else {
      Issue.record("Expected third block statement to be EmptyStatement")
      return
    }
  }

  @Test func parsesNestedBlockStatement() throws {
    let program = try parseProgram("{{ 7; }}")

    #expect(program.body.count == 1)
    let outerBlock = try blockStatement(program.body[0])
    #expect(outerBlock.body.count == 1)

    let innerBlock = try blockStatement(outerBlock.body[0])
    #expect(innerBlock.body.count == 1)
    #expect(try numericValue(innerBlock.body[0]) == 7)
  }

  @Test func parsesForStatementWithVariableInitializer() throws {
    let program = try parseProgram("for (let i = 0; i < 10; i = i + 1) {}")

    #expect(program.body.count == 1)
    let forStatement = try forIterationStatement(program.body[0])

    guard case let .variable(variable) = try #require(forStatement.start) else {
      Issue.record("Expected variable for-statement initializer")
      throw TestFailure()
    }

    #expect(variable.declarations.count == 1)
    #expect(variable.declarations[0].id == "i")
    #expect(try numericValue(#require(variable.declarations[0].initializer)) == 0)

    let condition = try binaryExpression(#require(forStatement.cond))
    #expect(condition.operatorValue == "<")
    #expect(try identifierValue(condition.left) == "i")
    #expect(try numericValue(condition.right) == 10)

    let update = try assignmentExpression(#require(forStatement.update))
    #expect(update.operatorValue == "=")
    #expect(try identifierValue(update.left) == "i")
  }

  @Test func parsesForStatementWithExpressionInitializer() throws {
    let program = try parseProgram("for (i = 0; i < 10; i = i + 1) {}")

    #expect(program.body.count == 1)
    let forStatement = try forIterationStatement(program.body[0])

    guard case let .expression(expression) = try #require(forStatement.start) else {
      Issue.record("Expected expression for-statement initializer")
      throw TestFailure()
    }

    let initializer = try assignmentExpression(expression)
    #expect(initializer.operatorValue == "=")
    #expect(try identifierValue(initializer.left) == "i")
    #expect(try numericValue(initializer.right) == 0)
  }

  @Test func parsesWhileStatement() throws {
    let program = try parseProgram("while (x < 10) { x = x + 1; }")

    #expect(program.body.count == 1)
    let whileStatement = try whileIterationStatement(program.body[0])

    let condition = try binaryExpression(whileStatement.condition)
    #expect(condition.operatorValue == "<")
    #expect(try identifierValue(condition.left) == "x")
    #expect(try numericValue(condition.right) == 10)

    #expect(whileStatement.body.body.count == 1)
    let bodyExpression = try expressionStatementValue(whileStatement.body.body[0])
    let assignment = try assignmentExpression(bodyExpression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")
  }

  @Test func parsesDoWhileStatement() throws {
    let program = try parseProgram("do { x = x + 1; } while (x < 10);")

    #expect(program.body.count == 1)
    let doWhileStatement = try whileIterationStatement(program.body[0])

    #expect(doWhileStatement.body.body.count == 1)
    let bodyExpression = try expressionStatementValue(doWhileStatement.body.body[0])
    let assignment = try assignmentExpression(bodyExpression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")

    let condition = try binaryExpression(doWhileStatement.condition)
    #expect(condition.operatorValue == "<")
    #expect(try identifierValue(condition.left) == "x")
    #expect(try numericValue(condition.right) == 10)
  }

  @Test func parsesForStatementWithEmptyClauses() throws {
    let program = try parseProgram("for (;;) {}")

    #expect(program.body.count == 1)
    let forStatement = try forIterationStatement(program.body[0])

    #expect(forStatement.start == nil)
    #expect(forStatement.cond == nil)
    #expect(forStatement.update == nil)
    #expect(forStatement.body.body.isEmpty)
  }

  @Test func parsesForStatementWithOmittedClauses() throws {
    let program = try parseProgram("for (; i < 10; i = i + 1) { x; }")

    #expect(program.body.count == 1)
    let forStatement = try forIterationStatement(program.body[0])

    #expect(forStatement.start == nil)

    let condition = try binaryExpression(#require(forStatement.cond))
    #expect(condition.operatorValue == "<")
    #expect(try identifierValue(condition.left) == "i")
    #expect(try numericValue(condition.right) == 10)

    let update = try assignmentExpression(#require(forStatement.update))
    #expect(update.operatorValue == "=")
    #expect(try identifierValue(update.left) == "i")

    #expect(forStatement.body.body.count == 1)
    #expect(try identifierValue(expressionStatementValue(forStatement.body.body[0])) == "x")
  }

  @Test func parsesForStatementWithOnlyUpdateClause() throws {
    let program = try parseProgram("for (;; i = i + 1) {}")

    #expect(program.body.count == 1)
    let forStatement = try forIterationStatement(program.body[0])

    #expect(forStatement.start == nil)
    #expect(forStatement.cond == nil)

    let update = try assignmentExpression(#require(forStatement.update))
    #expect(update.operatorValue == "=")
    #expect(try identifierValue(update.left) == "i")
    #expect(forStatement.body.body.isEmpty)
  }

  @Test func printsIterationStatementTree() throws {
    let program = try parseProgram("while (x) { x = 1; }")

    let expectedTree = """
    Program
    └─ IterationStatement
       ├─ Condition
       │  └─ IdentifierExpression x
       └─ Body
          └─ ExpressionStatement
             └─ AssignmentExpression (=)
                ├─ IdentifierExpression x
                └─ NumericLiteral 1
    """

    #expect(program.treeDescription == expectedTree)
  }

  @Test func skipsWhitespaceAndComments() throws {
    let program = try parseProgram(
      """

      // leading comment
      1;
      /* block comment */
      "two";
      """
    )

    #expect(program.body.count == 2)
    #expect(try numericValue(program.body[0]) == 1)
    #expect(try stringValue(program.body[1]) == "two")
  }

  @Test func parsesAdditionExpression() throws {
    let program = try parseProgram("1 + 2;")
    let expression = try expressionStatementValue(program.body[0])

    let binary = try binaryExpression(expression)
    #expect(binary.operatorValue == "+")
    #expect(try numericValue(binary.left) == 1)
    #expect(try numericValue(binary.right) == 2)
  }

  @Test func parsesSubtractionExpression() throws {
    let program = try parseProgram("5 - 3;")
    let expression = try expressionStatementValue(program.body[0])

    let binary = try binaryExpression(expression)
    #expect(binary.operatorValue == "-")
    #expect(try numericValue(binary.left) == 5)
    #expect(try numericValue(binary.right) == 3)
  }

  @Test func parsesAdditiveExpressionLeftAssociatively() throws {
    let program = try parseProgram("1 + 2 - 3;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "-")
    #expect(try numericValue(root.right) == 3)

    let left = try binaryExpression(root.left)
    #expect(left.operatorValue == "+")
    #expect(try numericValue(left.left) == 1)
    #expect(try numericValue(left.right) == 2)
  }

  @Test func parsesMultiplicationExpression() throws {
    let program = try parseProgram("2 * 3;")
    let expression = try expressionStatementValue(program.body[0])

    let binary = try binaryExpression(expression)
    #expect(binary.operatorValue == "*")
    #expect(try numericValue(binary.left) == 2)
    #expect(try numericValue(binary.right) == 3)
  }

  @Test func parsesDivisionExpression() throws {
    let program = try parseProgram("8 / 4;")
    let expression = try expressionStatementValue(program.body[0])

    let binary = try binaryExpression(expression)
    #expect(binary.operatorValue == "/")
    #expect(try numericValue(binary.left) == 8)
    #expect(try numericValue(binary.right) == 4)
  }

  @Test func parsesMultiplicativeExpressionLeftAssociatively() throws {
    let program = try parseProgram("8 / 4 * 2;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "*")
    #expect(try numericValue(root.right) == 2)

    let left = try binaryExpression(root.left)
    #expect(left.operatorValue == "/")
    #expect(try numericValue(left.left) == 8)
    #expect(try numericValue(left.right) == 4)
  }

  @Test func parsesMultiplicativeExpressionBeforeAdditiveExpression() throws {
    let program = try parseProgram("1 + 2 * 3;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "+")
    #expect(try numericValue(root.left) == 1)

    let right = try binaryExpression(root.right)
    #expect(right.operatorValue == "*")
    #expect(try numericValue(right.left) == 2)
    #expect(try numericValue(right.right) == 3)
  }

  @Test func parsesParenthesizedExpressionBeforeMultiplication() throws {
    let program = try parseProgram("(1 + 2) * 3;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "*")
    #expect(try numericValue(root.right) == 3)

    let left = try binaryExpression(root.left)
    #expect(left.operatorValue == "+")
    #expect(try numericValue(left.left) == 1)
    #expect(try numericValue(left.right) == 2)
  }

  @Test func parsesLogicalNotUnaryExpression() throws {
    let program = try parseProgram("!x;")
    let expression = try expressionStatementValue(program.body[0])

    let unary = try unaryExpression(expression)
    #expect(unary.operatorValue == "!")
    #expect(try identifierValue(unary.argument) == "x")
  }

  @Test func parsesUnaryExpressionBeforeMultiplicativeExpression() throws {
    let program = try parseProgram("!x * y;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "*")
    #expect(try identifierValue(root.right) == "y")

    let left = try unaryExpression(root.left)
    #expect(left.operatorValue == "!")
    #expect(try identifierValue(left.argument) == "x")
  }

  @Test func parsesParenthesizedLogicalExpressionAsUnaryArgument() throws {
    let program = try parseProgram("!(x && y);")
    let expression = try expressionStatementValue(program.body[0])

    let unary = try unaryExpression(expression)
    #expect(unary.operatorValue == "!")

    let argument = try logicalExpression(unary.argument)
    #expect(argument.operatorValue == "&&")
    #expect(try identifierValue(argument.left) == "x")
    #expect(try identifierValue(argument.right) == "y")
  }

  @Test func parsesRelationalOperators() throws {
    let cases: [(source: String, operatorValue: String)] = [
      ("1 > 2;", ">"),
      ("1 >= 2;", ">="),
      ("1 < 2;", "<"),
      ("1 <= 2;", "<="),
    ]

    for testCase in cases {
      let program = try parseProgram(testCase.source)
      let expression = try expressionStatementValue(program.body[0])

      let relational = try binaryExpression(expression)
      #expect(relational.operatorValue == testCase.operatorValue)
      #expect(try numericValue(relational.left) == 1)
      #expect(try numericValue(relational.right) == 2)
    }
  }

  @Test func parsesAdditiveExpressionBeforeRelationalExpression() throws {
    let program = try parseProgram("x + 5 > 10;")
    let expression = try expressionStatementValue(program.body[0])

    let relational = try binaryExpression(expression)
    #expect(relational.operatorValue == ">")
    #expect(try numericValue(relational.right) == 10)

    let left = try binaryExpression(relational.left)
    #expect(left.operatorValue == "+")
    #expect(try identifierValue(left.left) == "x")
    #expect(try numericValue(left.right) == 5)
  }

  @Test func parsesMultiplicativeExpressionBeforeRelationalExpression() throws {
    let program = try parseProgram("1 + 2 < 3 * 4;")
    let expression = try expressionStatementValue(program.body[0])

    let relational = try binaryExpression(expression)
    #expect(relational.operatorValue == "<")

    let left = try binaryExpression(relational.left)
    #expect(left.operatorValue == "+")
    #expect(try numericValue(left.left) == 1)
    #expect(try numericValue(left.right) == 2)

    let right = try binaryExpression(relational.right)
    #expect(right.operatorValue == "*")
    #expect(try numericValue(right.left) == 3)
    #expect(try numericValue(right.right) == 4)
  }

  @Test func parsesRelationalExpressionOnAssignmentRightSide() throws {
    let program = try parseProgram("x = a < b + 1;")
    let expression = try expressionStatementValue(program.body[0])

    let assignment = try assignmentExpression(expression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")

    let relational = try binaryExpression(assignment.right)
    #expect(relational.operatorValue == "<")
    #expect(try identifierValue(relational.left) == "a")

    let right = try binaryExpression(relational.right)
    #expect(right.operatorValue == "+")
    #expect(try identifierValue(right.left) == "b")
    #expect(try numericValue(right.right) == 1)
  }

  @Test func parsesEqualityOperators() throws {
    let cases: [(source: String, operatorValue: String)] = [
      ("1 == 2;", "=="),
      ("1 != 2;", "!="),
    ]

    for testCase in cases {
      let program = try parseProgram(testCase.source)
      let expression = try expressionStatementValue(program.body[0])

      let equality = try binaryExpression(expression)
      #expect(equality.operatorValue == testCase.operatorValue)
      #expect(try numericValue(equality.left) == 1)
      #expect(try numericValue(equality.right) == 2)
    }
  }

  @Test func parsesEqualityExpressionLeftAssociatively() throws {
    let program = try parseProgram("1 == 2 != 3;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try binaryExpression(expression)
    #expect(root.operatorValue == "!=")
    #expect(try numericValue(root.right) == 3)

    let left = try binaryExpression(root.left)
    #expect(left.operatorValue == "==")
    #expect(try numericValue(left.left) == 1)
    #expect(try numericValue(left.right) == 2)
  }

  @Test func parsesRelationalExpressionBeforeEqualityExpression() throws {
    let program = try parseProgram("1 < 2 == 3 > 4;")
    let expression = try expressionStatementValue(program.body[0])

    let equality = try binaryExpression(expression)
    #expect(equality.operatorValue == "==")

    let left = try binaryExpression(equality.left)
    #expect(left.operatorValue == "<")
    #expect(try numericValue(left.left) == 1)
    #expect(try numericValue(left.right) == 2)

    let right = try binaryExpression(equality.right)
    #expect(right.operatorValue == ">")
    #expect(try numericValue(right.left) == 3)
    #expect(try numericValue(right.right) == 4)
  }

  @Test func parsesEqualityExpressionOnAssignmentRightSide() throws {
    let program = try parseProgram("x = a == b < 1;")
    let expression = try expressionStatementValue(program.body[0])

    let assignment = try assignmentExpression(expression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")

    let equality = try binaryExpression(assignment.right)
    #expect(equality.operatorValue == "==")
    #expect(try identifierValue(equality.left) == "a")

    let right = try binaryExpression(equality.right)
    #expect(right.operatorValue == "<")
    #expect(try identifierValue(right.left) == "b")
    #expect(try numericValue(right.right) == 1)
  }

  @Test func parsesLogicalAndExpressionInVariableInitializer() throws {
    let program = try parseProgram("let y = x && z;")

    #expect(program.body.count == 1)
    let variable = try variableStatement(program.body[0])
    let initializer = try #require(variable.declarations[0].initializer)

    let logical = try logicalExpression(initializer)
    #expect(logical.operatorValue == "&&")
    #expect(try identifierValue(logical.left) == "x")
    #expect(try identifierValue(logical.right) == "z")
  }

  @Test func parsesDotMemberExpression() throws {
    let program = try parseProgram("object.property;")
    let expression = try expressionStatementValue(program.body[0])

    let member = try memberExpression(expression)
    #expect(member.computed == false)
    #expect(try identifierValue(member.object) == "object")
    #expect(try identifierValue(member.property) == "property")
  }

  @Test func parsesComputedMemberExpression() throws {
    let program = try parseProgram("object[property];")
    let expression = try expressionStatementValue(program.body[0])

    let member = try memberExpression(expression)
    #expect(member.computed == true)
    #expect(try identifierValue(member.object) == "object")
    #expect(try identifierValue(member.property) == "property")
  }

  @Test func parsesChainedMemberExpression() throws {
    let program = try parseProgram("object.property[index];")
    let expression = try expressionStatementValue(program.body[0])

    let root = try memberExpression(expression)
    #expect(root.computed == true)
    #expect(try identifierValue(root.property) == "index")

    let object = try memberExpression(root.object)
    #expect(object.computed == false)
    #expect(try identifierValue(object.object) == "object")
    #expect(try identifierValue(object.property) == "property")
  }

  @Test func parsesMemberExpressionAsAssignmentTarget() throws {
    let program = try parseProgram("object.property = 1;")
    let expression = try expressionStatementValue(program.body[0])

    let assignment = try assignmentExpression(expression)
    #expect(assignment.operatorValue == "=")
    #expect(try numericValue(assignment.right) == 1)

    let target = try memberExpression(assignment.left)
    #expect(target.computed == false)
    #expect(try identifierValue(target.object) == "object")
    #expect(try identifierValue(target.property) == "property")
  }

  @Test func parsesCallExpressionWithoutArguments() throws {
    let program = try parseProgram("foo();")
    let expression = try expressionStatementValue(program.body[0])

    let call = try funcCallExpression(expression)
    #expect(try identifierValue(call.callee) == "foo")
    #expect(call.arguments.isEmpty)
  }

  @Test func parsesCallExpressionWithArguments() throws {
    let program = try parseProgram("foo(x, y + 2);")
    let expression = try expressionStatementValue(program.body[0])

    let call = try funcCallExpression(expression)
    #expect(try identifierValue(call.callee) == "foo")
    #expect(call.arguments.count == 2)
    #expect(try identifierValue(call.arguments[0]) == "x")

    let secondArgument = try binaryExpression(call.arguments[1])
    #expect(secondArgument.operatorValue == "+")
    #expect(try identifierValue(secondArgument.left) == "y")
    #expect(try numericValue(secondArgument.right) == 2)
  }

  @Test func parsesAssignmentExpressionAsCallArgument() throws {
    let program = try parseProgram("foo(bar = 1, baz + 2);")
    let expression = try expressionStatementValue(program.body[0])

    let call = try funcCallExpression(expression)
    #expect(call.arguments.count == 2)

    let firstArgument = try assignmentExpression(call.arguments[0])
    #expect(firstArgument.operatorValue == "=")
    #expect(try identifierValue(firstArgument.left) == "bar")
    #expect(try numericValue(firstArgument.right) == 1)

    let secondArgument = try binaryExpression(call.arguments[1])
    #expect(secondArgument.operatorValue == "+")
    #expect(try identifierValue(secondArgument.left) == "baz")
    #expect(try numericValue(secondArgument.right) == 2)
  }

  @Test func parsesArrayLiteralExpression() throws {
    let program = try parseProgram("[x, y + 2, foo(z)];")
    let expression = try expressionStatementValue(program.body[0])

    let array = try arrayLiteral(expression)
    #expect(array.elements.count == 3)
    #expect(try identifierValue(array.elements[0]) == "x")

    let secondElement = try binaryExpression(array.elements[1])
    #expect(secondElement.operatorValue == "+")
    #expect(try identifierValue(secondElement.left) == "y")
    #expect(try numericValue(secondElement.right) == 2)

    let thirdElement = try funcCallExpression(array.elements[2])
    #expect(try identifierValue(thirdElement.callee) == "foo")
    #expect(thirdElement.arguments.count == 1)
    #expect(try identifierValue(thirdElement.arguments[0]) == "z")
  }

  @Test func parsesEmptyArrayLiteralExpression() throws {
    let program = try parseProgram("[];")
    let expression = try expressionStatementValue(program.body[0])

    let array = try arrayLiteral(expression)
    #expect(array.elements.isEmpty)
  }

  @Test func parsesArrayLiteralAsCallArgument() throws {
    let program = try parseProgram("graph.run([x, y, z], t1, t2);")
    let expression = try expressionStatementValue(program.body[0])

    let call = try funcCallExpression(expression)
    #expect(call.arguments.count == 3)

    let callee = try memberExpression(call.callee)
    #expect(callee.computed == false)
    #expect(try identifierValue(callee.object) == "graph")
    #expect(try identifierValue(callee.property) == "run")

    let firstArgument = try arrayLiteral(call.arguments[0])
    #expect(firstArgument.elements.count == 3)
    #expect(try identifierValue(firstArgument.elements[0]) == "x")
    #expect(try identifierValue(firstArgument.elements[1]) == "y")
    #expect(try identifierValue(firstArgument.elements[2]) == "z")
    #expect(try identifierValue(call.arguments[1]) == "t1")
    #expect(try identifierValue(call.arguments[2]) == "t2")
  }

  @Test func parseFailsForAssignmentInArrayLiteralElement() throws {
    let parser = Parser()

    let program = try parser.parse("[y = 2];")

    #expect(program == nil)
    #expect(parser.results.contains("Unexpected token"))
    #expect(parser.results.contains("SIMPLE_ASSIGNMENT"))
  }

  @Test func parsesMemberCallExpression() throws {
    let program = try parseProgram("object.method();")
    let expression = try expressionStatementValue(program.body[0])

    let call = try funcCallExpression(expression)
    #expect(call.arguments.isEmpty)

    let callee = try memberExpression(call.callee)
    #expect(callee.computed == false)
    #expect(try identifierValue(callee.object) == "object")
    #expect(try identifierValue(callee.property) == "method")
  }

  @Test func parsesChainedCallExpression() throws {
    let program = try parseProgram("foo()();")
    let expression = try expressionStatementValue(program.body[0])

    let outerCall = try funcCallExpression(expression)
    #expect(outerCall.arguments.isEmpty)

    let innerCall = try funcCallExpression(outerCall.callee)
    #expect(innerCall.arguments.isEmpty)
    #expect(try identifierValue(innerCall.callee) == "foo")
  }

  @Test func parsesClassDeclarationWithoutSuperclass() throws {
    let program = try parseProgram("class Point {}")

    #expect(program.body.count == 1)
    let classDeclaration = try classDeclarationStatement(program.body[0])
    #expect(try identifierValue(classDeclaration.id) == "Point")
    #expect(classDeclaration.superClass == nil)
    #expect(classDeclaration.body.body.isEmpty)
  }

  @Test func parsesClassDeclarationWithSuperclass() throws {
    let program = try parseProgram("class Point extends Shape {}")

    #expect(program.body.count == 1)
    let classDeclaration = try classDeclarationStatement(program.body[0])
    #expect(try identifierValue(classDeclaration.id) == "Point")
    #expect(try identifierValue(#require(classDeclaration.superClass)) == "Shape")
    #expect(classDeclaration.body.body.isEmpty)
  }

  @Test func parsesThisMemberAssignmentInClassMethod() throws {
    let program = try parseProgram(
      "class Point { def constructor(x, y) { this.x = x; this.y = y; } }"
    )

    let classDeclaration = try classDeclarationStatement(program.body[0])
    #expect(try identifierValue(classDeclaration.id) == "Point")
    #expect(classDeclaration.body.body.count == 1)

    let constructor = try functionDeclarationStatement(classDeclaration.body.body[0])
    #expect(constructor.name == "constructor")
    #expect(constructor.params == ["x", "y"])
    #expect(constructor.body.body.count == 2)

    let firstAssignment = try assignmentExpression(expressionStatementValue(constructor.body.body[0]))
    #expect(firstAssignment.operatorValue == "=")
    #expect(try identifierValue(firstAssignment.right) == "x")

    let firstTarget = try memberExpression(firstAssignment.left)
    #expect(firstTarget.computed == false)
    try requireThisExpression(firstTarget.object)
    #expect(try identifierValue(firstTarget.property) == "x")

    let secondAssignment = try assignmentExpression(expressionStatementValue(constructor.body.body[1]))
    #expect(secondAssignment.operatorValue == "=")
    #expect(try identifierValue(secondAssignment.right) == "y")

    let secondTarget = try memberExpression(secondAssignment.left)
    #expect(secondTarget.computed == false)
    try requireThisExpression(secondTarget.object)
    #expect(try identifierValue(secondTarget.property) == "y")
  }

  @Test func parsesNewExpression() throws {
    let program = try parseProgram("let point = new Point(1, 2);")
    let variable = try variableStatement(program.body[0])
    let initializer = try #require(variable.declarations[0].initializer)

    let newExpression = try newExpression(initializer)
    #expect(try identifierValue(newExpression.callee) == "Point")
    #expect(newExpression.arguments.count == 2)
    #expect(try numericValue(newExpression.arguments[0]) == 1)
    #expect(try numericValue(newExpression.arguments[1]) == 2)
  }

  @Test func parsesNamespacedNewExpression() throws {
    let program = try parseProgram("let point = new Geometry.Point();")
    let variable = try variableStatement(program.body[0])
    let initializer = try #require(variable.declarations[0].initializer)

    let newExpression = try newExpression(initializer)
    #expect(newExpression.arguments.isEmpty)

    let callee = try memberExpression(newExpression.callee)
    #expect(callee.computed == false)
    #expect(try identifierValue(callee.object) == "Geometry")
    #expect(try identifierValue(callee.property) == "Point")
  }

  @Test func parsesSuperCallInClassMethod() throws {
    let program = try parseProgram(
      "class Child extends Parent { def constructor(x) { super(x); } }"
    )

    let classDeclaration = try classDeclarationStatement(program.body[0])
    #expect(try identifierValue(#require(classDeclaration.superClass)) == "Parent")

    let constructor = try functionDeclarationStatement(classDeclaration.body.body[0])
    let call = try funcCallExpression(expressionStatementValue(constructor.body.body[0]))
    try requireSuperExpression(call.callee)
    #expect(call.arguments.count == 1)
    #expect(try identifierValue(call.arguments[0]) == "x")
  }

  @Test func debugTreeIncludesOOPNodes() throws {
    let program = try parseProgram(
      "class Child extends Parent { def constructor(x) { this.x = x; super(x); } } let child = new Child(1);"
    )
    let treeDescription = program.treeDescription

    #expect(treeDescription.contains("ClassDeclaration Child"))
    #expect(treeDescription.contains("SuperClass"))
    #expect(treeDescription.contains("ThisExpression"))
    #expect(treeDescription.contains("SuperExpression"))
    #expect(treeDescription.contains("NewExpression"))
  }

  @Test func parsesStringLoopAndCalls() throws {
    let program = try parseProgram(
      #"""
      let s = "Hello world";

      let i = 0;

      while ( i < s.length ) {
          console.log(i, s[i]);
          i += 1;
      }

      square(2);

      getCallback()();
      """#
    )

    #expect(program.body.count == 5)
  }

  @Test func parsesDefaultEditorExample() throws {
    let program = try parseProgram(Parser.defaultExampleSource)

    #expect(program.body.count > 0)
  }

  @Test func parsesSimpleAssignmentExpression() throws {
    let program = try parseProgram("x = 1;")
    let expression = try expressionStatementValue(program.body[0])

    let assignment = try assignmentExpression(expression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")
    #expect(try numericValue(assignment.right) == 1)
  }

  @Test func parsesComplexAssignmentOperators() throws {
    let cases: [(source: String, operatorValue: String)] = [
      ("x += 1;", "+="),
      ("x -= 1;", "-="),
      ("x *= 1;", "*="),
      ("x /= 1;", "/="),
    ]

    for testCase in cases {
      let program = try parseProgram(testCase.source)
      let expression = try expressionStatementValue(program.body[0])

      let assignment = try assignmentExpression(expression)
      #expect(assignment.operatorValue == testCase.operatorValue)
      #expect(try identifierValue(assignment.left) == "x")
      #expect(try numericValue(assignment.right) == 1)
    }
  }

  @Test func parsesAssignmentRightAssociatively() throws {
    let program = try parseProgram("x = y = 1;")
    let expression = try expressionStatementValue(program.body[0])

    let root = try assignmentExpression(expression)
    #expect(root.operatorValue == "=")
    #expect(try identifierValue(root.left) == "x")

    let right = try assignmentExpression(root.right)
    #expect(right.operatorValue == "=")
    #expect(try identifierValue(right.left) == "y")
    #expect(try numericValue(right.right) == 1)
  }

  @Test func parsesAssignmentAfterAdditiveExpressionOnRightSide() throws {
    let program = try parseProgram("x = 1 + 2 * 3;")
    let expression = try expressionStatementValue(program.body[0])

    let assignment = try assignmentExpression(expression)
    #expect(assignment.operatorValue == "=")
    #expect(try identifierValue(assignment.left) == "x")

    let right = try binaryExpression(assignment.right)
    #expect(right.operatorValue == "+")
    #expect(try numericValue(right.left) == 1)

    let multiplied = try binaryExpression(right.right)
    #expect(multiplied.operatorValue == "*")
    #expect(try numericValue(multiplied.left) == 2)
    #expect(try numericValue(multiplied.right) == 3)
  }

  @Test func parseFailsForInvalidAssignmentTarget() throws {
    let parser = Parser()

    let program = try parser.parse("x + y = 1;")

    #expect(program == nil)
    #expect(parser.results.contains("Unexpected assignment operator"))
  }

  @Test func printsAdditiveExpressionTree() throws {
    let parser = Parser()
    let program = try #require(try parser.parse("1 + 2 - 3;"))

    let expectedTree = """
    Program
    └─ ExpressionStatement
       └─ BinaryExpression (-)
          ├─ BinaryExpression (+)
          │  ├─ NumericLiteral 1
          │  └─ NumericLiteral 2
          └─ NumericLiteral 3
    """

    #expect(program.treeDescription == expectedTree)
    #expect(parser.results == expectedTree)
  }

  @Test func printsPrecedenceInExpressionTree() throws {
    let program = try parseProgram("1 + 2 * 3;")

    let expectedTree = """
    Program
    └─ ExpressionStatement
       └─ BinaryExpression (+)
          ├─ NumericLiteral 1
          └─ BinaryExpression (*)
             ├─ NumericLiteral 2
             └─ NumericLiteral 3
    """

    #expect(program.treeDescription == expectedTree)
  }

  @Test func printsParenthesizedPrecedenceInExpressionTree() throws {
    let program = try parseProgram("(1 + 2) * 3;")

    let expectedTree = """
    Program
    └─ ExpressionStatement
       └─ BinaryExpression (*)
          ├─ BinaryExpression (+)
          │  ├─ NumericLiteral 1
          │  └─ NumericLiteral 2
          └─ NumericLiteral 3
    """

    #expect(program.treeDescription == expectedTree)
  }

  @Test func printsVariableStatementTree() throws {
    let program = try parseProgram("let x = 1, y;")

    let expectedTree = """
    Program
    └─ VariableStatement
       ├─ VariableDeclaration x
       │  └─ NumericLiteral 1
       └─ VariableDeclaration y
    """

    #expect(program.treeDescription == expectedTree)
  }

  @Test func printsFunctionDeclarationTree() throws {
    let program = try parseProgram("def add(x, y) { return x + y; }")

    let expectedTree = """
    Program
    └─ FunctionDeclaration add
       ├─ Params
       │  ├─ Param x
       │  └─ Param y
       └─ Body
          └─ ReturnStatement
             └─ BinaryExpression (+)
                ├─ IdentifierExpression x
                └─ IdentifierExpression y
    """

    #expect(program.treeDescription == expectedTree)
  }

  @Test func parseFailsForMissingSemicolon() throws {
    let parser = Parser()

    let program = try parser.parse("42")

    #expect(program == nil)
    #expect(parser.results.contains("Unexpected end of input"))
  }

  @Test func parseFailsForUnknownToken() throws {
    let parser = Parser()

    let program = try parser.parse("@;")

    #expect(program == nil)
    #expect(parser.results.contains("Unexpected token"))
  }

  @Test func parseFailsForMissingClosingParenthesis() throws {
    let parser = Parser()

    let program = try parser.parse("(1 + 2;")

    #expect(program == nil)
    #expect(parser.results.contains("Unexpected token"))
    #expect(parser.results.contains("RIGHT_BRACE"))
  }
}

private func parseProgram(_ input: String) throws -> Program {
  let parser = Parser()
  let program = try parser.parse(input)
  return try #require(program)
}

private func expressionStatementValue(_ statement: Statement) throws -> Expression {
  guard case let .Expression(expressionStatement) = statement else {
    Issue.record("Expected ExpressionStatement")
    throw TestFailure()
  }

  return expressionStatement.value
}

private func blockStatement(_ statement: Statement) throws -> BlockStatement {
  guard case let .Block(blockStatement) = statement else {
    Issue.record("Expected BlockStatement")
    throw TestFailure()
  }

  return blockStatement
}

private func variableStatement(_ statement: Statement) throws -> VariableStatement {
  guard case let .Variable(variableStatement) = statement else {
    Issue.record("Expected VariableStatement")
    throw TestFailure()
  }

  return variableStatement
}

private func functionDeclarationStatement(_ statement: Statement) throws -> FunctionDeclarationStatement {
  guard case let .Function(functionStatement) = statement else {
    Issue.record("Expected FunctionDeclaration")
    throw TestFailure()
  }

  return functionStatement
}

private func classDeclarationStatement(_ statement: Statement) throws -> ClassDeclarationStatement {
  guard case let .ClassDeclaration(classDeclarationStatement) = statement else {
    Issue.record("Expected ClassDeclaration")
    throw TestFailure()
  }

  return classDeclarationStatement
}

private func returnStatement(_ statement: Statement) throws -> ReturnStatement {
  guard case let .Return(returnStatement) = statement else {
    Issue.record("Expected ReturnStatement")
    throw TestFailure()
  }

  return returnStatement
}

private func iterationStatement(_ statement: Statement) throws -> IterationStatement {
  guard case let .Iteration(iterationStatement) = statement else {
    Issue.record("Expected IterationStatement")
    throw TestFailure()
  }

  return iterationStatement
}

private func forIterationStatement(_ statement: Statement) throws -> ForIterationStatement {
  guard case let .forLoop(forStatement) = try iterationStatement(statement) else {
    Issue.record("Expected ForStatement")
    throw TestFailure()
  }

  return forStatement
}

private func whileIterationStatement(_ statement: Statement) throws -> WhileIterationStatement {
  guard case let .whileLoop(whileStatement) = try iterationStatement(statement) else {
    Issue.record("Expected WhileStatement")
    throw TestFailure()
  }

  return whileStatement
}

private func binaryExpression(_ expression: Expression) throws -> BinaryExpression {
  guard case let .binaryExpression(binaryExpression) = expression else {
    Issue.record("Expected BinaryExpression")
    throw TestFailure()
  }

  return binaryExpression
}

private func assignmentExpression(_ expression: Expression) throws -> AssignmentExpression {
  guard case let .assignmentExpression(assignmentExpression) = expression else {
    Issue.record("Expected AssignmentExpression")
    throw TestFailure()
  }

  return assignmentExpression
}

private func logicalExpression(_ expression: Expression) throws -> LogicalExpression {
  guard case let .logicalExpression(logicalExpression) = expression else {
    Issue.record("Expected LogicalExpression")
    throw TestFailure()
  }

  return logicalExpression
}

private func unaryExpression(_ expression: Expression) throws -> UnaryExpression {
  guard case let .unaryExpression(unaryExpression) = expression else {
    Issue.record("Expected UnaryExpression")
    throw TestFailure()
  }

  return unaryExpression
}

private func memberExpression(_ expression: Expression) throws -> MemberExpression {
  guard case let .memberExpression(memberExpression) = expression else {
    Issue.record("Expected MemberExpression")
    throw TestFailure()
  }

  return memberExpression
}

private func funcCallExpression(_ expression: Expression) throws -> FuncCallExpression {
  guard case let .funcCallExpression(funcCallExpression) = expression else {
    Issue.record("Expected FuncCallExpression")
    throw TestFailure()
  }

  return funcCallExpression
}

private func arrayLiteral(_ expression: Expression) throws -> ArrayLiteral {
  guard case let .arrayLiteral(arrayLiteral) = expression else {
    Issue.record("Expected ArrayLiteral")
    throw TestFailure()
  }

  return arrayLiteral
}

private func newExpression(_ expression: Expression) throws -> NewExpression {
  guard case let .newExpression(newExpression) = expression else {
    Issue.record("Expected NewExpression")
    throw TestFailure()
  }

  return newExpression
}

private func requireThisExpression(_ expression: Expression) throws {
  guard case .thisExpression = expression else {
    Issue.record("Expected ThisExpression")
    throw TestFailure()
  }
}

private func requireSuperExpression(_ expression: Expression) throws {
  guard case .superExpression = expression else {
    Issue.record("Expected SuperExpression")
    throw TestFailure()
  }
}

private func numericValue(_ statement: Statement) throws -> Double {
  try numericValue(expressionStatementValue(statement))
}

private func numericValue(_ expression: Expression) throws -> Double {
  guard case let .numericLiteral(node) = expression else {
    Issue.record("Expected NumericLiteral")
    throw TestFailure()
  }

  return node.value
}

private func identifierValue(_ expression: Expression) throws -> String {
  guard case let .identifierExpression(node) = expression else {
    Issue.record("Expected IdentifierExpression")
    throw TestFailure()
  }

  return node.value
}

private func stringValue(_ statement: Statement) throws -> String {
  let expression = try expressionStatementValue(statement)

  guard case let .stringLiteral(node) = expression else {
    Issue.record("Expected StringLiteral")
    throw TestFailure()
  }

  return node.value
}

private func booleanValue(_ expression: Expression) throws -> Bool {
  guard case let .booleanLiteral(node) = expression else {
    Issue.record("Expected BooleanLiteral")
    throw TestFailure()
  }

  return node.value
}

private func requireNullLiteral(_ expression: Expression) throws {
  guard case .nullLiteral = expression else {
    Issue.record("Expected NullLiteral")
    throw TestFailure()
  }
}

private struct TestFailure: Error {}
