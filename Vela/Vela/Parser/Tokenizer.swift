//
//  Tokenizer.swift
//  ToyParser
//
//  Created by Tao Xu on 1/2/25.
//

import Foundation

final class Tokenizer {
  private var input: String = ""
  private var cursor: String.Index!

  init() {}

  func initialize(_ input: String) {
    self.input = input
    cursor = input.startIndex
  }

  func isEOF() -> Bool {
    return cursor == input.endIndex
  }

  func hasMoreTokens() -> Bool {
    return cursor < input.endIndex
  }

  /// Lazy generation: we don't tokenize the input at once
  func getNextToken() throws(LexerError) -> Token? {
    print("getNextToken()")
    guard hasMoreTokens() else {
      print("Error: No more tokens!")
      return nil
    }

    let remaining = String(input[cursor...])
    print("remaining: \(remaining)")

    // match the next token
    for spec in Token.specs {
      if let tokenValue = match(spec.regex, in: remaining) {
        // advance the curor
        cursor = input.index(cursor, offsetBy: tokenValue.count)

        print("[Tokenizer] matched: \(tokenValue)")

        // skip comments, linebreaks, etc
        if spec.type == .BLANK || spec.type == .COMMENT || spec.type == .COMMENT_BLOCK {
          print("[Tokenizer] skip the matched token: \(spec.type)")
          return try getNextToken()
        }

        return Token(
          type: tokenType(for: tokenValue, defaultType: spec.type),
          value: tokenValue
        )
      }
    }
    print("Error: can match the next token with specs!")
    throw .unexpectedToken(String(remaining.prefix(1)))
  }

  private func match(_ regex: Regex<Substring>, in input: String) -> String? {
    // eager matching: return the first match result
    guard let result = input.firstMatch(of: regex) else {
      return nil
    }
    return String(result.output)
  }

  private func cursorPosition() -> Int {
    input.distance(from: input.startIndex, to: cursor)
  }

  private func tokenType(for value: String, defaultType: TokenType) -> TokenType {
    guard defaultType == .IDENTIFIER, Self.keywords.contains(value) else {
      return defaultType
    }

    return .KEYWORD(keyword: value)
  }

  private static let keywords: Set<String> = [
    "let",
    "if",
    "else",
    "true",
    "false",
    "null",
    "while",
    "for",
    "do",
    "def",
    "return",
    "break",
    "continue",
    "class",
    "extends",
    "super",
    "new",
    "this",
  ]
}
