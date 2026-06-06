//
//  Node+Debug.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

import Foundation

// MARK: DEBUG

extension Program {
  var treeDescription: String {
    ASTPrinter().print(self)
  }
}

extension Program: CustomStringConvertible {
  var description: String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    do {
      let data = try encoder.encode(self)
      return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
      return #"{"error":"Failed to encode AST"}"#
    }
  }
}

private struct ASTPrinter {
  func print(_ program: Program) -> String {
    var lines = ["Program"]
    appendStatements(program.body, to: &lines, prefix: "")
    return lines.joined(separator: "\n")
  }

  private func appendStatements(_ statements: [Statement], to lines: inout [String], prefix: String) {
    for (index, statement) in statements.enumerated() {
      appendStatement(
        statement,
        to: &lines,
        prefix: prefix,
        isLast: index == statements.count - 1
      )
    }
  }

  private func appendStatement(_ statement: Statement, to lines: inout [String], prefix: String, isLast: Bool) {
    lines.append("\(prefix)\(branch(isLast))\(label(for: statement))")

    switch statement {
    case .Empty:
      return
    case let .Block(block):
      appendStatements(block.body, to: &lines, prefix: childPrefix(prefix, isLast: isLast))
    case let .Expression(expressionStatement):
      appendExpression(
        expressionStatement.value,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast),
        isLast: true
      )
    case let .Variable(variableStatement):
      appendVariableStatement(
        variableStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    case let .If(ifStatement):
      appendIfStatement(
        ifStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    case let .Iteration(iterationStatement):
      appendIterationStatement(
        iterationStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    case let .Function(functionStatement):
      appendFunctionDeclaration(
        functionStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    case let .Return(returnStatement):
      appendReturnStatement(
        returnStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    case .Break:
      break
    case .Continue:
      break
    case let .ClassDeclaration(classStatement):
      appendClassDeclaration(
        classStatement,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast)
      )
    }
  }

  private func appendClassDeclaration(
    _ statement: ClassDeclarationStatement,
    to lines: inout [String],
    prefix: String
  ) {
    if let superClass = statement.superClass {
      lines.append("\(prefix)├─ SuperClass")
      appendExpression(superClass, to: &lines, prefix: "\(prefix)│  ", isLast: true)
      lines.append("\(prefix)└─ Body")
      appendStatements(statement.body.body, to: &lines, prefix: "\(prefix)   ")
      return
    }

    lines.append("\(prefix)└─ Body")
    appendStatements(statement.body.body, to: &lines, prefix: "\(prefix)   ")
  }

  private func appendFunctionDeclaration(
    _ statement: FunctionDeclarationStatement,
    to lines: inout [String],
    prefix: String
  ) {
    if !statement.params.isEmpty {
      lines.append("\(prefix)├─ Params")
      for (index, param) in statement.params.enumerated() {
        lines.append("\(prefix)│  \(branch(index == statement.params.count - 1))Param \(param)")
      }
    }

    lines.append("\(prefix)└─ Body")
    appendStatements(statement.body.body, to: &lines, prefix: "\(prefix)   ")
  }

  private func appendReturnStatement(
    _ statement: ReturnStatement,
    to lines: inout [String],
    prefix: String
  ) {
    guard let value = statement.value else {
      return
    }

    appendExpression(value, to: &lines, prefix: prefix, isLast: true)
  }

  private func appendIterationStatement(_ statement: IterationStatement, to lines: inout [String], prefix: String) {
    switch statement {
    case let .whileLoop(whileStatement):
      lines.append("\(prefix)├─ Condition")
      appendExpression(whileStatement.condition, to: &lines, prefix: "\(prefix)│  ", isLast: true)
      lines.append("\(prefix)└─ Body")
      appendStatements(whileStatement.body.body, to: &lines, prefix: "\(prefix)   ")
    case let .forLoop(forStatement):
      appendForStatement(forStatement, to: &lines, prefix: prefix)
    }
  }

  private func appendForStatement(_ statement: ForIterationStatement, to lines: inout [String], prefix: String) {
    if let start = statement.start {
      lines.append("\(prefix)├─ Start")
      appendForStatementInit(start, to: &lines, prefix: "\(prefix)│  ")
    }

    if let cond = statement.cond {
      lines.append("\(prefix)├─ Condition")
      appendExpression(cond, to: &lines, prefix: "\(prefix)│  ", isLast: true)
    }

    if let update = statement.update {
      lines.append("\(prefix)├─ Update")
      appendExpression(update, to: &lines, prefix: "\(prefix)│  ", isLast: true)
    }

    lines.append("\(prefix)└─ Body")
    appendStatements(statement.body.body, to: &lines, prefix: "\(prefix)   ")
  }

  private func appendForStatementInit(_ initNode: ForStatementInit, to lines: inout [String], prefix: String) {
    switch initNode {
    case let .variable(statement):
      appendVariableStatement(statement, to: &lines, prefix: prefix)
    case let .expression(expression):
      appendExpression(expression, to: &lines, prefix: prefix, isLast: true)
    }
  }

  private func appendIfStatement(_ statement: IFStatement, to lines: inout [String], prefix: String) {
    lines.append("\(prefix)├─ Condition")
    appendExpression(statement.condition, to: &lines, prefix: "\(prefix)│  ", isLast: true)
    lines.append("\(prefix)├─ IfBody")
    appendStatements(statement.ifBody.body, to: &lines, prefix: "\(prefix)│  ")

    guard let elseBody = statement.elseBody else {
      return
    }

    lines.append("\(prefix)└─ ElseBody")
    appendStatements(elseBody.body, to: &lines, prefix: "\(prefix)   ")
  }

  private func appendVariableStatement(_ statement: VariableStatement, to lines: inout [String], prefix: String) {
    for (index, declaration) in statement.declarations.enumerated() {
      appendVariableDeclaration(
        declaration,
        to: &lines,
        prefix: prefix,
        isLast: index == statement.declarations.count - 1
      )
    }
  }

  private func appendVariableDeclaration(
    _ declaration: VariableDeclaration,
    to lines: inout [String],
    prefix: String,
    isLast: Bool
  ) {
    lines.append("\(prefix)\(branch(isLast))VariableDeclaration \(declaration.id)")

    guard let initializer = declaration.initializer else {
      return
    }

    appendExpression(
      initializer,
      to: &lines,
      prefix: childPrefix(prefix, isLast: isLast),
      isLast: true
    )
  }

  private func appendExpression(_ expression: Expression, to lines: inout [String], prefix: String, isLast: Bool) {
    lines.append("\(prefix)\(branch(isLast))\(label(for: expression))")

    let left: Expression
    let right: Expression
    switch expression {
    case let .binaryExpression(node):
      left = node.left
      right = node.right
    case let .assignmentExpression(node):
      left = node.left
      right = node.right
    case let .logicalExpression(node):
      left = node.left
      right = node.right
    case let .unaryExpression(node):
      appendExpression(
        node.argument,
        to: &lines,
        prefix: childPrefix(prefix, isLast: isLast),
        isLast: true
      )
      return
    case let .memberExpression(node):
      left = node.object
      right = node.property
    case let .funcCallExpression(node):
      let nextPrefix = childPrefix(prefix, isLast: isLast)
      appendExpression(node.callee, to: &lines, prefix: nextPrefix, isLast: node.arguments.isEmpty)

      guard !node.arguments.isEmpty else {
        return
      }

      lines.append("\(nextPrefix)└─ Arguments")
      let argumentsPrefix = childPrefix(nextPrefix, isLast: true)
      for (index, argument) in node.arguments.enumerated() {
        appendExpression(argument, to: &lines, prefix: argumentsPrefix, isLast: index == node.arguments.count - 1)
      }
      return
    case let .newExpression(node):
      let nextPrefix = childPrefix(prefix, isLast: isLast)
      appendExpression(node.callee, to: &lines, prefix: nextPrefix, isLast: node.arguments.isEmpty)

      guard !node.arguments.isEmpty else {
        return
      }

      lines.append("\(nextPrefix)└─ Arguments")
      let argumentsPrefix = childPrefix(nextPrefix, isLast: true)
      for (index, argument) in node.arguments.enumerated() {
        appendExpression(argument, to: &lines, prefix: argumentsPrefix, isLast: index == node.arguments.count - 1)
      }
      return
    case let .arrayLiteral(node):
      let nextPrefix = childPrefix(prefix, isLast: isLast)
      for (index, element) in node.elements.enumerated() {
        appendExpression(element, to: &lines, prefix: nextPrefix, isLast: index == node.elements.count - 1)
      }
      return
    case let .dictionaryLiteral(node):
      let nextPrefix = childPrefix(prefix, isLast: isLast)
      for (index, entry) in node.entries.enumerated() {
        appendDictionaryEntry(entry, to: &lines, prefix: nextPrefix, isLast: index == node.entries.count - 1)
      }
      return
    default:
      return
    }

    let nextPrefix = childPrefix(prefix, isLast: isLast)
    appendExpression(left, to: &lines, prefix: nextPrefix, isLast: false)
    appendExpression(right, to: &lines, prefix: nextPrefix, isLast: true)
  }

  private func appendDictionaryEntry(
    _ entry: DictionaryEntry,
    to lines: inout [String],
    prefix: String,
    isLast: Bool
  ) {
    lines.append("\(prefix)\(branch(isLast))DictionaryEntry")

    let nextPrefix = childPrefix(prefix, isLast: isLast)
    lines.append("\(nextPrefix)├─ Key")
    appendExpression(entry.key, to: &lines, prefix: "\(nextPrefix)│  ", isLast: true)
    lines.append("\(nextPrefix)└─ Value")
    appendExpression(entry.value, to: &lines, prefix: "\(nextPrefix)   ", isLast: true)
  }

  private func label(for statement: Statement) -> String {
    switch statement {
    case .Empty:
      return "EmptyStatement"
    case .Block:
      return "BlockStatement"
    case .Expression:
      return "ExpressionStatement"
    case .Variable:
      return "VariableStatement"
    case .If:
      return "IFStatement"
    case .Iteration:
      return "IterationStatement"
    case let .Function(function):
      return "FunctionDeclaration \(function.name)"
    case .Return:
      return "ReturnStatement"
    case .Break:
      return "BreakStatement"
    case .Continue:
      return "ContinueStatement"
    case let .ClassDeclaration(classStatement):
      return "ClassDeclaration \(className(classStatement.id))"
    }
  }

  private func label(for expression: Expression) -> String {
    switch expression {
    case let .numericLiteral(node):
      return "NumericLiteral \(format(node.value))"
    case let .stringLiteral(node):
      return #"StringLiteral "\#(escaped(node.value))""#
    case let .binaryExpression(node):
      return "BinaryExpression (\(node.operatorValue))"
    case let .assignmentExpression(node):
      return "AssignmentExpression (\(node.operatorValue))"
    case let .identifierExpression(node):
      return "IdentifierExpression \(node.value)"
    case let .booleanLiteral(node):
      return "BooleanLiteral \(node.value)"
    case .nullLiteral:
      return "NullLiteral"
    case let .logicalExpression(node):
      return "LogicalExpression (\(node.operatorValue))"
    case let .unaryExpression(node):
      return "UnaryExpression (\(node.operatorValue))"
    case let .memberExpression(node):
      return "MemberExpression (\(node.computed ? "computed" : "property"))"
    case .funcCallExpression:
      return "FuncCallExpression"
    case .thisExpression:
      return "ThisExpression"
    case .superExpression:
      return "SuperExpression"
    case .newExpression:
      return "NewExpression"
    case .arrayLiteral:
      return "ArrayLiteral"
    case .dictionaryLiteral:
      return "DictionaryLiteral"
    }
  }

  private func className(_ expression: Expression) -> String {
    if case let .identifierExpression(node) = expression {
      return node.value
    }
    return expression.type
  }

  private func branch(_ isLast: Bool) -> String {
    isLast ? "└─ " : "├─ "
  }

  private func childPrefix(_ prefix: String, isLast: Bool) -> String {
    prefix + (isLast ? "   " : "│  ")
  }

  private func format(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }

    return String(value)
  }

  private func escaped(_ value: String) -> String {
    value
      .replacingOccurrences(of: #"\"#, with: #"\\"#)
      .replacingOccurrences(of: #"""#, with: #"\""#)
  }
}
