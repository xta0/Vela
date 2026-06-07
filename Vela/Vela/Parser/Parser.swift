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

  /// Program
  ///   : StatementList
  ///   ;
  ///
  /// Examples:
  /// `1;`
  /// `let x = 1; x + 2;`
  func programBuilder() throws -> Program {
    try Program(body: statementListBuilder())
  }
}

extension Parser {
  static let defaultExampleSource = #"""
  // Vela executable language demo
  /*
    Covers comments, literals, variables, expressions, blocks, conditionals,
    loops, functions, arrays, dictionaries, builtins, classes, self, and
    inheritance. The final expression returns a summary object.
  */

  ;

  let emptyValue, number = 42, text = "Hello world", singleQuoted = 'ok';
  let flag = true, missing = null;
  let total = (1 + 2) * 3 - 4 / 2;
  let negative = -total;
  let same = total == 7;
  let compare = total >= 3 && total != 0 || !false;
  let shortCircuit = true || unknownName;

  {
    let scoped = total + number;
    number = scoped - total;
  }

  if (compare) {
    number += 1;
  } else {
    number -= 1;
  }

  let i = 0, whileTotal = 0;
  while (i < 6) {
    i += 1;
    if (i == 2) {
      continue;
    }
    if (i == 5) {
      break;
    }
    whileTotal += i;
  }

  let doCount = 0;
  do {
    doCount += 1;
  } while (doCount < 2);

  let forTotal = 0;
  for (let j = 0; j < 5; j += 1) {
    if (j == 3) {
      continue;
    }
    forTotal += j;
  }

  def noop() {
    return;
  }

  let bonus = 3;
  def addBonus(x) {
    return x + bonus;
  }

  def square(n) {
    return n * n;
  }

  let numbers = [1, 2, 3];
  append(numbers, 4);
  numbers[0] += 10;
  let lastNumber = pop(numbers);
  let missingNumber = numbers[99];

  let record = { name: "Vela", "count": 1 };
  record.count += 1;
  record["language"] = "toy";
  set(record, "status", "ok");
  let recordKeys = keys(record);
  let hasStatus = has(record, "status");

  class Named {
    def label() {
      return self.name;
    }

    def kind() {
      return "named";
    }
  }

  class Point extends Named {
    def init(x, y, name) {
      self.x = x;
      self["y"] = y;
      self.name = name;
    }

    def lengthSquared() {
      return self.x * self.x + self["y"] * self["y"];
    }

    def kind() {
      return "point";
    }
  }

  let point = new Point(3, 4, "origin");
  point.z = 12;
  point["tag"] = "cartesian";
  let inheritedLabel = point.label();
  let overriddenKind = point.kind();
  let printed = print("point", inheritedLabel, str(point.lengthSquared()));

  let summary = {
    empty: emptyValue,
    flag: flag,
    missing: missing,
    text: text,
    singleQuoted: singleQuoted,
    total: total,
    negative: negative,
    same: same,
    compare: compare,
    shortCircuit: shortCircuit,
    number: number,
    whileTotal: whileTotal,
    doCount: doCount,
    forTotal: forTotal,
    noReturn: noop(),
    functionResult: addBonus(square(2)),
    numbers: numbers,
    lastNumber: lastNumber,
    missingNumber: missingNumber,
    record: record,
    recordKeys: recordKeys,
    hasStatus: hasStatus,
    recordLength: len(record),
    pointLength: point.lengthSquared(),
    inheritedLabel: inheritedLabel,
    overriddenKind: overriddenKind,
    missingMember: point.missing,
    pointType: type(point),
    pointLengthText: str(point.lengthSquared()),
    printed: printed
  };
  summary;
  """#
}
