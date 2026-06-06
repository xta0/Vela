//
//  LHS.swift
//  ToyParser
//
//  Created by Tao Xu on 5/10/26.
//

extension Parser {
  /// LeftHandSideExpression
  ///   : MemberExpression
  ///   ;
  ///
  /// Examples:
  /// `x`
  /// `total`
  func leftHandSideExpressionBuilder() throws -> Expression {
    try callMemberExpressionBuilder()
  }

  /// CallMemberExpression
  ///  : MemberExpression
  ///  | CallExpression
  ///  ;
  ///
  /// Examples:
  /// `x`
  /// `object.property`
  /// `foo()`
  /// `foo(bar)`
  /// `super(x, y)`
  func callMemberExpressionBuilder() throws -> Expression {
    // super call:
    if lookahead?.type == .KEYWORD(keyword: "super") {
      return try callExpressionBuilder(superExpressionBuilder())
    }

    // member part, might be part of a call
    let callee = try memberExpressionBuilder()

    // see if we have a call expression
    if lookahead?.type == .LEFT_BRACE {
      return try callExpressionBuilder(callee)
    }

    // simple member expression
    return callee
  }

  /// Generic call expression helper
  ///
  /// CallExpression
  ///  : Callee Arguments
  ///  ;
  /// Callee (chain-expression)
  ///  : MemberExpression
  ///  | CallExpression
  ///  ;
  ///
  /// Examples:
  /// `foo()`
  /// `foo(bar, baz)`
  /// `object.method()`
  /// `foo()()`
  func callExpressionBuilder(_ callee: Expression) throws -> Expression {
    let funcCallExpNode = try FuncCallExpression(callee: callee, arguments: argumentsExpressionBuilder())
    var funcCallExp = Expression.funcCallExpression(funcCallExpNode)
    if lookahead?.type == .LEFT_BRACE {
      funcCallExp = try callExpressionBuilder(.funcCallExpression(funcCallExpNode))
    }
    return funcCallExp
  }

  /// Arguments
  ///  : '(' OptArgList ')'
  ///  ;
  ///
  /// Examples:
  /// `()`
  /// `(x)`
  /// `(x, y)`
  func argumentsExpressionBuilder() throws -> [Expression] {
    try eat(.LEFT_BRACE)
    let argListExp = lookahead?.type == .RIGHT_BRACE ? [] : try argumentListExpressionBuilder()
    try eat(.RIGHT_BRACE)
    return argListExp
  }

  /// ArgumentList
  ///  : AssignmentExpression
  ///  | ArgumentLIst ',' AssignmentExpression foo(bar=1, baz=2)
  ///  ;
  ///
  /// Examples:
  /// `x`
  /// `x, y`
  /// `x = 1, y + 2`
  func argumentListExpressionBuilder() throws -> [Expression] {
    var argList = try [assignmentExpressionBuilder()]

    while lookahead?.type == .COMMA {
      try eat(.COMMA)
      try argList.append(assignmentExpressionBuilder())
    }

    return argList
  }

  /// MemberExpression
  ///  : PrimaryExpression
  ///  | MemberExpression '.' Identifier
  ///  | MemberExpression '[' Expression ']'
  ///  ;
  ///
  /// Examples:
  /// `x`
  /// `object.property`
  /// `object[property]`
  /// `object.property[index]`
  func memberExpressionBuilder() throws -> Expression {
    var object = try primaryExpressionBuilder()

    while lookahead?.type == .DOT || lookahead?.type == .LEFT_SQUARE_BRACKET {
      if lookahead?.type == .DOT {
        try eat(.DOT)
        let property = try identifierBuilder()
        object = .memberExpression(MemberExpression(computed: false, object: object, property: property))
      }
      if lookahead?.type == .LEFT_SQUARE_BRACKET {
        try eat(.LEFT_SQUARE_BRACKET)
        let property = try expressionBuilder()
        try eat(.RIGHT_SQUARE_BRACKET)
        object = .memberExpression(MemberExpression(computed: true, object: object, property: property))
      }
    }
    return object
  }
}
