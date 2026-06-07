//
//  Class.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  /// ClassDeclaration
  ///  : 'class' Identifier OptClassExtends BlockStatement
  ///  ;
  ///
  /// Examples:
  /// `class Point {}`
  /// `class Point extends Shape {}`
  /// `class Point { def init(x, y) { self.x = x; self.y = y; } }`
  func classDeclarationStamentBuilder() throws -> ClassDeclarationStatement {
    try eat(.KEYWORD(keyword: "class"))
    let id = try identifierBuilder()
    var classExtendExp: Expression?
    if lookahead?.type == .KEYWORD(keyword: "extends") {
      classExtendExp = try classExtendExpressionBuilder()
    }
    // Class bodies currently reuse BlockStatement syntax, but evaluation only
    // supports function declarations as methods.
    let body = try blockStatementBuilder()
    return ClassDeclarationStatement(id: id, superClass: classExtendExp, body: body)
  }
}
