//
//  Token.swift
//  ToyParser
//
//  Created by Tao Xu on 3/15/26.
//

enum TokenType {
  case SEMICOLON
  case COMMA
  case DOT
  case COLON

  case LEFT_CURLY_BRACE
  case RIGHT_CURLY_BRACE

  case LEFT_SQUARE_BRACKET
  case RIGHT_SQUARE_BRACKET

  case LEFT_BRACE
  case RIGHT_BRACE

  case NUMBER
  case STRING

  case BLANK
  case COMMENT
  case COMMENT_BLOCK
  case UNKNOWN

  case ADD
  case MINUS
  case MUL
  case DIV

  case IDENTIFIER

  case SIMPLE_ASSIGNMENT
  case COMPLEX_ASSIGNMENT

  case KEYWORD(keyword: String)

  case RELATIONAL
  case EQUALITY
  case LOGICAL_AND
  case LOGICAL_OR

  // unary;
  case UNARY(op: String)
  case UNSUPPORTED
}

extension TokenType: Equatable {
  static func == (lhs: TokenType, rhs: TokenType) -> Bool {
    switch (lhs, rhs) {
    case (.SEMICOLON, .SEMICOLON),
         (.COMMA, .COMMA),
         (.DOT, .DOT),
         (.COLON, .COLON),
         (.LEFT_CURLY_BRACE, .LEFT_CURLY_BRACE),
         (.RIGHT_CURLY_BRACE, .RIGHT_CURLY_BRACE),
         (.LEFT_SQUARE_BRACKET, .LEFT_SQUARE_BRACKET),
         (.RIGHT_SQUARE_BRACKET, .RIGHT_SQUARE_BRACKET),
         (.LEFT_BRACE, .LEFT_BRACE),
         (.RIGHT_BRACE, .RIGHT_BRACE),
         (.NUMBER, .NUMBER),
         (.STRING, .STRING),
         (.BLANK, .BLANK),
         (.COMMENT, .COMMENT),
         (.COMMENT_BLOCK, .COMMENT_BLOCK),
         (.UNKNOWN, .UNKNOWN),
         (.ADD, .ADD),
         (.MINUS, .MINUS),
         (.MUL, .MUL),
         (.DIV, .DIV),
         (.IDENTIFIER, .IDENTIFIER),
         (.SIMPLE_ASSIGNMENT, .SIMPLE_ASSIGNMENT),
         (.RELATIONAL, .RELATIONAL),
         (.EQUALITY, .EQUALITY),
         (.LOGICAL_AND, .LOGICAL_AND),
         (.LOGICAL_OR, .LOGICAL_OR),
         (.COMPLEX_ASSIGNMENT, .COMPLEX_ASSIGNMENT):
      return true
    case let (.KEYWORD(lhsKeyword), .KEYWORD(rhsKeyword)):
      return lhsKeyword == rhsKeyword
    case let (.UNARY(lhs), .UNARY(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

struct Token {
  let type: TokenType
  let value: String
}

struct TokenSpec {
  let regex: Regex<Substring>
  let type: TokenType
}

extension Token {
  static let specs: [TokenSpec] = [
    TokenSpec(regex: /^\s/, type: .BLANK),
    TokenSpec(regex: /^\/\/.*/, type: .COMMENT),
    TokenSpec(regex: /^\/\*[\s\S]*?\*\//, type: .COMMENT),

    // ;, , ., :
    TokenSpec(regex: /^;/, type: .SEMICOLON),
    TokenSpec(regex: /^,/, type: .COMMA),
    TokenSpec(regex: /^\./, type: .DOT),
    TokenSpec(regex: /^:/, type: .COLON),

    // {..},[..], (..),
    TokenSpec(regex: /^\{/, type: .LEFT_CURLY_BRACE),
    TokenSpec(regex: /^\}/, type: .RIGHT_CURLY_BRACE),
    TokenSpec(regex: /^\[/, type: .LEFT_SQUARE_BRACKET),
    TokenSpec(regex: /^\]/, type: .RIGHT_SQUARE_BRACKET),
    TokenSpec(regex: /^\(/, type: .LEFT_BRACE),
    TokenSpec(regex: /^\)/, type: .RIGHT_BRACE),

    // number:
    TokenSpec(regex: /^\d+/, type: .NUMBER),

    // string:
    TokenSpec(regex: /^"[^"]*"/, type: .STRING),
    TokenSpec(regex: /^'[^']*'/, type: .STRING),

    // relational ops: >, <, >=, <=
    TokenSpec(regex: /^[><]=?/, type: .RELATIONAL),

    // equality ops: ==, !=
    // needs to be above unary and assignment
    TokenSpec(regex: /^==/, type: .EQUALITY),
    TokenSpec(regex: /^!=/, type: .EQUALITY),

    // logical ops: &&, ||
    TokenSpec(regex: /^&&/, type: .LOGICAL_AND),
    TokenSpec(regex: /^\|\|/, type: .LOGICAL_OR),

    // unary ops: !
    TokenSpec(regex: /^!/, type: .UNARY(op: "!")),

    // assignment: =, +=, -=, *=, /=
    TokenSpec(regex: /^[\*\+\-\/]=/, type: .COMPLEX_ASSIGNMENT),
    TokenSpec(regex: /^=/, type: .SIMPLE_ASSIGNMENT),

    // math ops: +, -, *, /
    TokenSpec(regex: /^\+/, type: .ADD),
    TokenSpec(regex: /^-/, type: .MINUS),
    TokenSpec(regex: /^\*/, type: .MUL),
    TokenSpec(regex: /^\//, type: .DIV),

    // keywords:
    // trailing word boundaries keep identifiers like `returnValue` from being
    // split into `return` plus `Value`.
    TokenSpec(regex: /^\blet\b/, type: .KEYWORD(keyword: "let")),
    TokenSpec(regex: /^\bif\b/, type: .KEYWORD(keyword: "if")),
    TokenSpec(regex: /^\belse\b/, type: .KEYWORD(keyword: "else")),
    TokenSpec(regex: /^\btrue\b/, type: .KEYWORD(keyword: "true")),
    TokenSpec(regex: /^\bfalse\b/, type: .KEYWORD(keyword: "false")),
    TokenSpec(regex: /^\bnull\b/, type: .KEYWORD(keyword: "null")),
    TokenSpec(regex: /^\bwhile\b/, type: .KEYWORD(keyword: "while")),
    TokenSpec(regex: /^\bfor\b/, type: .KEYWORD(keyword: "for")),
    TokenSpec(regex: /^\bdo\b/, type: .KEYWORD(keyword: "do")),
    TokenSpec(regex: /^\bdef\b/, type: .KEYWORD(keyword: "def")),
    TokenSpec(regex: /^\breturn\b/, type: .KEYWORD(keyword: "return")),
    TokenSpec(regex: /^\bbreak\b/, type: .KEYWORD(keyword: "break")),
    TokenSpec(regex: /^\bcontinue\b/, type: .KEYWORD(keyword: "continue")),
    TokenSpec(regex: /^\bclass\b/, type: .KEYWORD(keyword: "class")),
    TokenSpec(regex: /^\bextends\b/, type: .KEYWORD(keyword: "extends")),
    TokenSpec(regex: /^\bsuper\b/, type: .KEYWORD(keyword: "super")),
    TokenSpec(regex: /^\bnew\b/, type: .KEYWORD(keyword: "new")),
    TokenSpec(regex: /^\bself\b/, type: .KEYWORD(keyword: "self")),

    // identifiers (needs to checked after number):
    TokenSpec(regex: /^\w+/, type: .IDENTIFIER),
  ]
}

enum LexerError: Error, CustomStringConvertible {
  case unexpectedToken(String)

  var description: String {
    switch self {
    case let .unexpectedToken(token):
      return "Unexpected token: \"\(token)\""
    }
  }
}
