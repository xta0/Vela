//
//  Node.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

// ASTNode: concrete nodes that can appear in the AST:
//
// ASTNode
// ├─ Program
// ├─ EmptyStatement
// ├─ BlockStatement
// ├─ ExpressionStatement
// ├─ VariableStatement
// ├─ IFStatement
// ├─ WhileIterationStatement
// ├─ ForIterationStatement
// ├─ FunctionDeclarationStatement
// ├─ ReturnStatement
// ├─ BreakStatement
// ├─ ClassDeclarationStatement
// ├─ VariableDeclaration
// └─ Expression
//    ├─ NumericLiteral
//    ├─ StringLiteral
//    ├─ BooleanLiteral
//    ├─ NullLiteral
//    ├─ IdentifierExpression
//    ├─ BinaryExpression
//    ├─ LogicalExpression
//    ├─ UnaryExpression
//    ├─ AssignmentExpression
//    ├─ MemberExpression
//    ├─ FuncCallExpression
//    ├─ ThisExpression
//    ├─ SuperExpression
//    ├─ NewExpression
//    ├─ ArrayLiteral
//    └─ DictionaryLiteral
//
// Statement is a wrapper over statement node variants, not a concrete ASTNode.
protocol ASTNode {}

// MARK: Literal Expression

struct NumericLiteral: ASTNode, Encodable {
  let type = "NumericLiteral"
  let value: Double
}

struct StringLiteral: ASTNode, Encodable {
  let type = "StringLiteral"
  let value: String
}

struct BooleanLiteral: ASTNode, Encodable {
  let type = "BooleanLiteral"
  let value: Bool
}

struct NullLiteral: ASTNode, Encodable {
  let type = "NullLiteral"
  let value: Never?
}

// MARK: Expression

/// an AST node that produces a value
indirect enum Expression: ASTNode {
  var type: String {
    switch self {
    case let .numericLiteral(num):
      return num.type
    case let .stringLiteral(str):
      return str.type
    case let .booleanLiteral(bool):
      return bool.type
    case let .nullLiteral(null):
      return null.type
    case let .binaryExpression(exp):
      return exp.type
    case let .assignmentExpression(exp):
      return exp.type
    case let .identifierExpression(exp):
      return exp.type
    case let .logicalExpression(exp):
      return exp.type
    case let .unaryExpression(exp):
      return exp.type
    case let .memberExpression(exp):
      return exp.type
    case let .funcCallExpression(exp):
      return exp.type
    case let .thisExpression(exp):
      return exp.type
    case let .superExpression(exp):
      return exp.type
    case let .newExpression(exp):
      return exp.type
    case let .arrayLiteral(exp):
      return exp.type
    case let .dictionaryLiteral(exp):
      return exp.type
    }
  }

  case numericLiteral(NumericLiteral)
  case stringLiteral(StringLiteral)
  case booleanLiteral(BooleanLiteral)
  case nullLiteral(NullLiteral)
  case binaryExpression(BinaryExpression)
  case assignmentExpression(AssignmentExpression)
  case identifierExpression(IdentifierExpression)
  case logicalExpression(LogicalExpression)
  case unaryExpression(UnaryExpression)
  case memberExpression(MemberExpression)
  case funcCallExpression(FuncCallExpression)
  case thisExpression(ThisExpression)
  case superExpression(SuperExpression)
  case newExpression(NewExpression)
  case arrayLiteral(ArrayLiteral)
  case dictionaryLiteral(DictionaryLiteral)
}

extension Expression: Encodable {
  func encode(to encoder: Encoder) throws {
    switch self {
    case let .numericLiteral(node):
      try node.encode(to: encoder)
    case let .stringLiteral(node):
      try node.encode(to: encoder)
    case let .booleanLiteral(node):
      try node.encode(to: encoder)
    case let .nullLiteral(node):
      try node.encode(to: encoder)
    case let .binaryExpression(node):
      try node.encode(to: encoder)
    case let .assignmentExpression(node):
      try node.encode(to: encoder)
    case let .identifierExpression(node):
      try node.encode(to: encoder)
    case let .logicalExpression(node):
      try node.encode(to: encoder)
    case let .unaryExpression(node):
      try node.encode(to: encoder)
    case let .memberExpression(node):
      try node.encode(to: encoder)
    case let .funcCallExpression(node):
      try node.encode(to: encoder)
    case let .thisExpression(node):
      try node.encode(to: encoder)
    case let .superExpression(node):
      try node.encode(to: encoder)
    case let .newExpression(node):
      try node.encode(to: encoder)
    case let .arrayLiteral(node):
      try node.encode(to: encoder)
    case let .dictionaryLiteral(node):
      try node.encode(to: encoder)
    }
  }
}

// MARK: Binary Expression

// left: exp
// right: exp

struct BinaryExpression: ASTNode, Encodable {
  let type = "BinaryExpression"
  let operatorValue: String
  let left: Expression
  let right: Expression
}

// MARK: Assignment Expression

struct AssignmentExpression: ASTNode, Encodable {
  let type = "AssignmentExpression"
  let operatorValue: String
  let left: Expression
  let right: Expression
}

// MARK: Identifier Expression

struct IdentifierExpression: ASTNode, Encodable {
  let type = "IdentifierExpression"
  let value: String
}

// MARK: Declaration

struct VariableDeclaration: ASTNode, Encodable {
  let type = "VariableDeclaration"
  let id: String
  let initializer: Expression?
}

// MARK: Logical Expression

struct LogicalExpression: ASTNode, Encodable {
  let type = "LogicalExpression"
  let operatorValue: String
  let left: Expression
  let right: Expression
}

// MARK: Unary Expression

struct UnaryExpression: ASTNode, Encodable {
  let type = "UnaryExpression"
  let operatorValue: String
  let argument: Expression
}

// MARK: Member Expression

struct MemberExpression: ASTNode, Encodable {
  let type = "MemberExpression"
  let computed: Bool
  let object: Expression
  let property: Expression
}

// MARK: Function Call Expression

struct FuncCallExpression: ASTNode, Encodable {
  let type = "FuncCallExpression"
  let callee: Expression // Identifier expression, FuncCallExpression, MemberExpression
  let arguments: [Expression] // Identifier expressions
}

// MARK: This Expression

struct ThisExpression: ASTNode, Encodable {
  let type = "ThisExpression"
}

// MARK: Super Expression

struct SuperExpression: ASTNode, Encodable {
  let type = "SuperExpression"
}

// MARK: New Expression

struct NewExpression: ASTNode, Encodable {
  let type = "NewExpression"
  let callee: Expression
  let arguments: [Expression]
}

// MARK: Array Literal

struct ArrayLiteral: ASTNode, Encodable {
  let type = "ArrayLiteral"
  let elements: [Expression]
}

// MARK: Dictionary Literal

struct DictionaryLiteral: ASTNode, Encodable {
  let type = "DictionaryLiteral"
  let entries: [DictionaryEntry]
}

struct DictionaryEntry: ASTNode, Encodable {
  let key: Expression
  let value: Expression
}

// MARK: Statements

enum Statement: Encodable {
  var type: String {
    switch self {
    case let .Empty(es): return es.type
    case let .Block(bs): return bs.type
    case let .Expression(exps): return exps.type
    case let .Variable(vs): return vs.type
    case let .If(s): return s.type
    case let .Iteration(s): return s.type
    case let .Function(f): return f.type
    case let .Return(r): return r.type
    case let .Break(b): return b.type
    case let .Continue(c): return c.type
    case let .ClassDeclaration(r): return r.type
    }
  }

  case Empty(EmptyStatement)
  case Block(BlockStatement)
  case Expression(ExpressionStatement)
  case Variable(VariableStatement)
  case If(IFStatement)
  case Iteration(IterationStatement)
  case Function(FunctionDeclarationStatement)
  case Return(ReturnStatement)
  case Break(BreakStatement)
  case Continue(ContinueStatement)
  case ClassDeclaration(ClassDeclarationStatement)
}

struct EmptyStatement: ASTNode, Encodable {
  let type = "EmptyStatement"
}

struct BlockStatement: ASTNode, Encodable {
  let type = "BlockStatement"
  let body: [Statement]
}

struct ExpressionStatement: ASTNode, Encodable {
  let type = "ExpressionStatement"
  let value: Expression
}

struct VariableStatement: ASTNode, Encodable {
  let type = "VariableStatement"
  let declarations: [VariableDeclaration]
}

struct IFStatement: ASTNode, Encodable {
  let type = "IFStatement"
  let condition: Expression
  let ifBody: BlockStatement
  let elseBody: BlockStatement?
}

enum IterationStatement: Encodable {
  case whileLoop(WhileIterationStatement)
  case forLoop(ForIterationStatement)

  var type: String {
    switch self {
    case .whileLoop: return "IterationStatement"
    case .forLoop: return "IterationStatement"
    }
  }
}

enum ForStatementInit: Encodable {
  case variable(VariableStatement)
  case expression(Expression)
}

struct WhileIterationStatement: ASTNode, Encodable {
  let type = "IterationStatement"
  let isDoWhile: Bool
  let condition: Expression
  let body: BlockStatement
}

struct ForIterationStatement: ASTNode, Encodable {
  let type = "ForStatement"
  let start: ForStatementInit?
  let cond: Expression?
  let update: Expression?
  let body: BlockStatement
}

struct FunctionDeclarationStatement: ASTNode, Encodable {
  let type = "FunctionDeclaration"
  let name: String
  let params: [String]
  let body: BlockStatement
}

struct ReturnStatement: ASTNode, Encodable {
  let type = "ReturnStatement"
  let value: Expression?
}

struct BreakStatement: ASTNode, Encodable {
  let type = "BreakStatement"
}

struct ContinueStatement: ASTNode, Encodable {
  let type = "ContinueStatement"
}

struct ClassDeclarationStatement: ASTNode, Encodable {
  let type = "ClassDeclarationStatement"
  let id: Expression
  let superClass: Expression?
  let body: BlockStatement
}

// MARK: Program

struct Program: ASTNode, Encodable {
  let type = "Program"
  let body: [Statement]
}
