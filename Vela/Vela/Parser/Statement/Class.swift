//
//  Class.swift
//  ToyParser
//
//  Created by Tao Xu on 6/1/26.
//

extension Parser {
  // ClassDeclaration
  //  : 'class' Identifier OptClassExtends BlockStatement
  //  ;
  //
  // Examples:
  // `class Point {}`
  // `class Point extends Shape {}`
  // `class Point { def constructor(x, y) { this.x = x; this.y = y; } }`
  func classDeclarationStamentBuilder() throws -> ClassDeclarationStatement {
    try eat(.KEYWORD(keyword: "class"))
    let id = try identifierBuilder()
    var classExtendExp: Expression?
    if lookahead?.type == .KEYWORD(keyword: "extends") {
      classExtendExp = try classExtendExpressionBuilder()
    }
    let body = try blockStatementBuilder()
    return ClassDeclarationStatement(id: id, superClass: classExtendExp, body: body)
  }
}
