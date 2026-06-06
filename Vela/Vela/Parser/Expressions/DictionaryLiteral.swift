//
//  DictionaryLiteral.swift
//  Vela
//
//  Created by Tao Xu on 6/2/26.
//

import Foundation

extension Parser {
  /// DictionaryLiteral
  ///   : LEFT_CURLY_BRACE DictionaryEntryListOpt RIGHT_CURLY_BRACE
  ///   ;
  ///
  /// DictionaryEntryList
  ///   : DictionaryEntry
  ///   | DictionaryEntryList COMMA DictionaryEntry
  ///   ;
  ///
  /// DictionaryEntry
  ///   : DictionaryKey COLON LogicalOrExpression
  ///   ;
  ///
  /// DictionaryKey
  ///   : IDENTIFIER
  ///   | STRING
  ///   ;
  ///
  /// Examples:
  /// `{}`
  /// `{ "name": "Vela", count: 3 }`
  func dictionaryLiteralBuilder() throws -> Expression {
    try eat(.LEFT_CURLY_BRACE)

    let entries = lookahead?.type == .RIGHT_CURLY_BRACE
      ? []
      : try dictionaryEntryListBuilder()

    try eat(.RIGHT_CURLY_BRACE)

    return .dictionaryLiteral(DictionaryLiteral(entries: entries))
  }

  private func dictionaryEntryListBuilder() throws -> [DictionaryEntry] {
    var entries = try [dictionaryEntryBuilder()]

    while lookahead?.type == .COMMA {
      try eat(.COMMA)
      try entries.append(dictionaryEntryBuilder())
    }

    return entries
  }

  private func dictionaryEntryBuilder() throws -> DictionaryEntry {
    let key = try dictionaryKeyBuilder()
    try eat(.COLON)
    let value = try logicalOrExpressionBuilder()

    return DictionaryEntry(key: key, value: value)
  }

  private func dictionaryKeyBuilder() throws -> Expression {
    switch lookahead?.type {
    case .IDENTIFIER:
      return try identifierBuilder()
    case .STRING:
      return try .stringLiteral(stringLiteralBuilder())
    default:
      throw ParserError.unexpectedExpressionToken(actual: lookahead?.type)
    }
  }
}
