//
//  IF.swift
//  ToyParser
//
//  Created by Tao Xu on 5/9/26.
//

extension Parser {
  /// IfStatement
  ///   : KEYWORD("if") LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ///   | KEYWORD("if") LEFT_BRACE Expression RIGHT_BRACE BlockStatement KEYWORD("else") BlockStatement
  ///   ;
  ///
  /// Examples:
  /// `if (x) {}`
  /// `if (x > 0) { y; } else { z; }`
  func ifStatementBuilder() throws -> IFStatement {
    try eat(.KEYWORD(keyword: "if"))
    try eat(.LEFT_BRACE)
    let conditionExp = try expressionBuilder()
    try eat(.RIGHT_BRACE)

    let ifBlock = try blockStatementBuilder()

    var elseBlock: BlockStatement?
    if lookahead?.type == .KEYWORD(keyword: "else") {
      try eat(.KEYWORD(keyword: "else"))
      elseBlock = try blockStatementBuilder()
    }
    return IFStatement(condition: conditionExp,
                       ifBody: ifBlock,
                       elseBody: elseBlock)
  }
}
