/**
 * ToyParser grammar.
 *
 * This file documents the grammar implemented by the hand-written Swift
 * recursive descent parser in ToyParser/ToyParser/Parser.
 *
 * Unlike eva/parser/eva-grammar.bnf, this file is not currently used to
 * generate the parser. It mirrors the parser's builder methods and token names.
 *
 * Examples:
 *
 * Program:
 *
 *   let s = "Hello world";
 *   let i = 0;
 *   while (i < s.length) {
 *     console.log(i, s[i]);
 *     i += 1;
 *   }
 *
 * Expressions:
 *
 *   x = y = 1
 *   a || b && c
 *   object.property[index]
 *   getCallback()()
 *   class Point extends Shape {}
 *   new Point(1, 2)
 */

// -----------------------------------------------
// Lexical grammar (tokens):

%lex

%%

\s+                    /* skip whitespace */
\/\/.*                 /* skip line comment */
\/\*[\s\S]*?\*\/       /* skip block comment */

;                      return 'SEMICOLON'
,                      return 'COMMA'
\.                     return 'DOT'

\{                     return 'LEFT_CURLY_BRACE'
\}                     return 'RIGHT_CURLY_BRACE'
\[                     return 'LEFT_SQUARE_BRACKET'
\]                     return 'RIGHT_SQUARE_BRACKET'
\(                     return 'LEFT_BRACE'
\)                     return 'RIGHT_BRACE'

\d+                    return 'NUMBER'
\"[^\"]*\"             return 'STRING'
\'[^\']*\'             return 'STRING'

[><]=?                 return 'RELATIONAL'
==                     return 'EQUALITY'
!=                     return 'EQUALITY'
&&                     return 'LOGICAL_AND'
\|\|                   return 'LOGICAL_OR'

!                      return 'UNARY'
[*+\-/]=               return 'COMPLEX_ASSIGNMENT'
=                      return 'SIMPLE_ASSIGNMENT'

[+\-]                  return 'ADD'
[*\/]                  return 'MUL'

\blet\b                return 'LET'
\bif\b                 return 'IF'
\belse\b               return 'ELSE'
\btrue\b               return 'TRUE'
\bfalse\b              return 'FALSE'
\bnull\b               return 'NULL'
\bwhile\b              return 'WHILE'
\bfor\b                return 'FOR'
\bdo\b                 return 'DO'
\bdef\b                return 'DEF'
\breturn\b             return 'RETURN'
\bclass\b              return 'CLASS'
\bextends\b            return 'EXTENDS'
\bsuper\b              return 'SUPER'
\bnew\b                return 'NEW'
\bthis\b               return 'THIS'

\w+                    return 'IDENTIFIER'

/lex

// -----------------------------------------------
// Syntactic grammar (BNF):

%%

Program
  : StatementList
  ;

StatementList
  : Statement
  | StatementList Statement
  ;

StatementListOpt
  : StatementList
  | /* empty */
  ;

Statement
  : EmptyStatement
  | BlockStatement
  | VariableStatement
  | IfStatement
  | IterationStatement
  | FunctionDeclaration
  | ReturnStatement
  | ClassDeclaration
  | ExpressionStatement
  ;

EmptyStatement
  : SEMICOLON
  ;

BlockStatement
  : LEFT_CURLY_BRACE StatementListOpt RIGHT_CURLY_BRACE
  ;

ExpressionStatement
  : Expression SEMICOLON
  ;

VariableStatement
  : LET VariableDeclarationList SEMICOLON
  ;

VariableStatementInit
  : LET VariableDeclarationList
  ;

VariableDeclarationList
  : VariableDeclaration
  | VariableDeclarationList COMMA VariableDeclaration
  ;

VariableDeclaration
  : IDENTIFIER VariableInitializerOpt
  ;

VariableInitializerOpt
  : SIMPLE_ASSIGNMENT AssignmentExpression
  | /* empty */
  ;

IfStatement
  : IF LEFT_BRACE Expression RIGHT_BRACE BlockStatement ElseStatementOpt
  ;

ElseStatementOpt
  : ELSE BlockStatement
  | /* empty */
  ;

IterationStatement
  : WhileStatement
  | DoWhileStatement
  | ForStatement
  ;

WhileStatement
  : WHILE LEFT_BRACE Expression RIGHT_BRACE BlockStatement
  ;

DoWhileStatement
  : DO BlockStatement WHILE LEFT_BRACE Expression RIGHT_BRACE SEMICOLON
  ;

ForStatement
  : FOR LEFT_BRACE ForStatementInitOpt SEMICOLON ExpressionOpt SEMICOLON ExpressionOpt RIGHT_BRACE BlockStatement
  ;

ForStatementInitOpt
  : ForStatementInit
  | /* empty */
  ;

ForStatementInit
  : VariableStatementInit
  | Expression
  ;

ExpressionOpt
  : Expression
  | /* empty */
  ;

FunctionDeclaration
  : DEF IDENTIFIER LEFT_BRACE FormalParameterListOpt RIGHT_BRACE BlockStatement
  ;

FormalParameterListOpt
  : FormalParameterList
  | /* empty */
  ;

FormalParameterList
  : IDENTIFIER
  | FormalParameterList COMMA IDENTIFIER
  ;

ReturnStatement
  : RETURN ReturnValueOpt SEMICOLON
  ;

ReturnValueOpt
  : Expression
  | /* empty */
  ;

ClassDeclaration
  : CLASS IDENTIFIER ClassExtendsOpt BlockStatement
  ;

ClassExtendsOpt
  : ClassExtends
  | /* empty */
  ;

ClassExtends
  : EXTENDS IDENTIFIER
  ;

Expression
  : AssignmentExpression
  ;

AssignmentExpression
  : LogicalOrExpression
  | LeftHandSideExpression AssignmentOperator AssignmentExpression
  ;

AssignmentOperator
  : SIMPLE_ASSIGNMENT
  | COMPLEX_ASSIGNMENT
  ;

LogicalOrExpression
  : LogicalAndExpression
  | LogicalOrExpression LOGICAL_OR LogicalAndExpression
  ;

LogicalAndExpression
  : EqualityExpression
  | LogicalAndExpression LOGICAL_AND EqualityExpression
  ;

EqualityExpression
  : RelationalExpression
  | EqualityExpression EQUALITY RelationalExpression
  ;

RelationalExpression
  : AdditiveExpression
  | RelationalExpression RELATIONAL AdditiveExpression
  ;

AdditiveExpression
  : MultiplicativeExpression
  | AdditiveExpression ADD MultiplicativeExpression
  ;

MultiplicativeExpression
  : UnaryExpression
  | MultiplicativeExpression MUL UnaryExpression
  ;

UnaryExpression
  : LeftHandSideExpression
  | UNARY UnaryExpression
  ;

LeftHandSideExpression
  : CallMemberExpression
  ;

CallMemberExpression
  : MemberExpression
  | CallExpression
  ;

CallExpression
  : Callee Arguments
  ;

Callee
  : MemberExpression
  | CallExpression
  | SuperExpression
  ;

Arguments
  : LEFT_BRACE ArgumentListOpt RIGHT_BRACE
  ;

ArgumentListOpt
  : ArgumentList
  | /* empty */
  ;

ArgumentList
  : AssignmentExpression
  | ArgumentList COMMA AssignmentExpression
  ;

MemberExpression
  : PrimaryExpression
  | MemberExpression DOT IDENTIFIER
  | MemberExpression LEFT_SQUARE_BRACKET Expression RIGHT_SQUARE_BRACKET
  ;

PrimaryExpression
  : Literal
  | ParenthesizedExpression
  | IDENTIFIER
  | ThisExpression
  | NewExpression
  ;

ParenthesizedExpression
  : LEFT_BRACE Expression RIGHT_BRACE
  ;

ThisExpression
  : THIS
  ;

SuperExpression
  : SUPER
  ;

NewExpression
  : NEW MemberExpression Arguments
  ;

Literal
  : NumericLiteral
  | StringLiteral
  | BooleanLiteral
  | NullLiteral
  ;

NumericLiteral
  : NUMBER
  ;

StringLiteral
  : STRING
  ;

BooleanLiteral
  : TRUE
  | FALSE
  ;

NullLiteral
  : NULL
  ;
