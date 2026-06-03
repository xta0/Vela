//
//  Parser.swift
//  ToyParser
//
//  Created by Tao Xu on 1/2/25.
//

import Foundation

enum ParserError: Error, CustomStringConvertible {
  case unexpectedEndOfInput(expected: TokenType)
  case unexpectedToken(actual: TokenType, expected: TokenType)
  case unexpectedExpressionToken(actual: TokenType?)
  case unexpectedLiteralProduction
  case unexpectedBinaryOperator(actual: TokenType)
  case unexpectedAssignmentOperator
  case unexpectedKeyword(keyword: String)
  case unexpectedIterationOperator(actual: TokenType)

  var description: String {
    switch self {
    case let .unexpectedEndOfInput(expected):
      return "Unexpected end of input, expected: \(expected)"
    case let .unexpectedToken(actual, expected):
      return "Unexpected token: \(actual), expected: \(expected)"
    case let .unexpectedExpressionToken(actual):
      return "Unexpected expression token: \(String(describing: actual))"
    case .unexpectedLiteralProduction:
      return "Literal: unexpected literal production"
    case let .unexpectedBinaryOperator(actual: actual):
      return "Unexpected binary operator: \(actual)"
    case .unexpectedAssignmentOperator:
      return "Unexpected assignment operator"
    case let .unexpectedKeyword(keyword: keyword):
      return "Unepected keyword: \(keyword)"
    case let .unexpectedIterationOperator(actual: actual):
      return "Unxpected iteration operator: \(actual)"
    }
  }
}

final class Parser: ObservableObject {
  @Published var results: String = ""
  @Published private(set) var ast: Program?

  private(set) var string: String = ""
  private(set) var lookahead: Token?

  private let tokenizer = Tokenizer()

  init() {}

  func clear() {
    results = ""
    ast = nil
  }

  @discardableResult
  func parse(_ input: String) throws -> Program? {
    string = input
    tokenizer.initialize(input)
    do {
      lookahead = try tokenizer.getNextToken()
      let ast = try programBuilder()
      self.ast = ast
      results = ast.treeDescription
      return ast
    } catch {
      ast = nil
      results = "\(error)"
    }
    return nil
  }

  @discardableResult
  func eat(_ tokenType: TokenType) throws -> Token {
    guard let token = lookahead else {
      throw ParserError.unexpectedEndOfInput(expected: tokenType)
    }

    guard token.type == tokenType else {
      throw ParserError.unexpectedToken(actual: token.type, expected: tokenType)
    }
    print("[Parser] Eat \(tokenType)")
    lookahead = try tokenizer.getNextToken()
    return token
  }

  // Program
  //   : StatementList
  //   ;
  //
  // Examples:
  // `1;`
  // `let x = 1; x + 2;`
  func programBuilder() throws -> Program {
    try Program(body: statementListBuilder())
  }
}

extension Parser {
  static let defaultExampleSource = #"""
  // VelaParser grammar demo
  /*
    Covers comments, literals, variables, blocks, conditionals, loops,
    functions, classes, calls, member access, assignments, and precedence.
  */

  ;

  let emptyValue;
  let number = 42, text = "Hello world", singleQuoted = 'ok';
  let flag = true, missing = null;
  let total = (1 + 2) * 3 - 4 / 2;
  let same = total == 7;
  let compare = total >= 3 && total != 0 || !false;
  let callbackValue = getCallback()();

  {
    let scoped = text[number];
    scoped = scoped;
  }

  if (compare) {
    console.log(text, singleQuoted);
  } else {
    console.log("fallback");
  }

  while (number > 0) {
    console.log(number, text[number]);
    number -= 1;
  }

  do {
    total += 1;
    total *= 2;
    total /= 2;
  } while (total <= 10);

  for (let i = 0; i < 3; i += 1) {
    point[i] = i;
  }

  def noop() {
    return;
  }

  def square(x) {
    return x * x;
  }

  class Shape {}

  class Point extends Shape {
    def constructor(x, y) {
      super(x, y);
      this.x = x;
      this["y"] = y;
    }

    def lengthSquared() {
      return this.x * this.x + this["y"] * this["y"];
    }
  }

  let point = new Geometry.Point(1, 2);
  point.x = point.x + 1;
  point["y"] = point.y + 2;
  square(2);
  """#
}
