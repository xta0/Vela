//
//  ContentView.swift
//  ToyParser
//
//  Created by Tao Xu on 1/2/25.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var parser = Parser()
  @State private var textFieldContent: String = Parser.defaultExampleSource
  @State private var outputMode: OutputMode = .tree
  @State private var evalResult: String = ""
  @State private var isShowingEvalResult = false
  @State private var isShowingEnvironment = false
  @State private var editorFontSize: CGFloat = 14
  private let footerHeight: CGFloat = 28

  private var outputText: String {
    if isShowingEvalResult {
      if isShowingEnvironment {
        return Eval.globalEnv.jsonDescription
      }

      return evalResult
    }

    switch outputMode {
    case .tree:
      return parser.results
    case .json:
      return parser.ast?.description ?? parser.results
    }
  }

  private func decreaseEditorFontSize() {
    editorFontSize = max(10, editorFontSize - 1)
  }

  private func increaseEditorFontSize() {
    editorFontSize = min(28, editorFontSize + 1)
  }

  private func parseSource() {
    _ = try? parser.parse(textFieldContent)
    isShowingEvalResult = false
    isShowingEnvironment = false
  }

  private func evalSource() {
    isShowingEnvironment = false
    Eval.globalEnv.clear()

    guard let ast = try? parser.parse(textFieldContent) else {
      evalResult = parser.results
      isShowingEvalResult = true
      return
    }

    do throws(EvalRuntimeError) {
      evalResult = try Eval.eval(ast).displayValue
    } catch {
      evalResult = "\(error)"
    }

    isShowingEvalResult = true
  }

  var body: some View {
    HStack(spacing: 0) {
      VStack {
        TextEditor(text: $textFieldContent)
          .font(.system(size: editorFontSize, design: .monospaced))
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.top)
          .padding(.horizontal)
        ZStack {
          HStack {
            Button {
              decreaseEditorFontSize()
            } label: {
              Text("-")
            }
            Button {
              increaseEditorFontSize()
            } label: {
              Text("+")
            }
            Spacer()
          }

          HStack {
            Button("Eval") {
              evalSource()
            }
            Button("Parse") {
              parseSource()
            }
            Button("Clear") {
              textFieldContent = ""
              parser.clear()
              Eval.globalEnv.clear()
              evalResult = ""
              isShowingEvalResult = false
              isShowingEnvironment = false
            }
            Button("Restore") {
              textFieldContent = Parser.defaultExampleSource
              isShowingEvalResult = false
              isShowingEnvironment = false
            }
          }
        }
        .frame(height: footerHeight)
        .padding(.horizontal)
        .padding(.bottom)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.gray.opacity(0.2))

      Divider() // Optional divider for visual separation

      // Right: TextView (TextEditor)
      VStack {
        TextEditor(text: .constant(outputText))
          .padding(.top)
          .padding(.horizontal)
        HStack {
          if isShowingEvalResult {
            Button("Env") {
              isShowingEnvironment = true
            }
          } else {
            Button(outputMode.buttonTitle) {
              outputMode.toggle()
            }
          }
        }
        .frame(height: footerHeight)
        .padding(.horizontal)
        .padding(.bottom)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.gray.opacity(0.1))
    }
    .frame(minWidth: 600, minHeight: 400) // Adjust minimum size
  }
}

private enum OutputMode {
  case tree
  case json

  var buttonTitle: String {
    switch self {
    case .tree:
      return "JSON"
    case .json:
      return "Tree"
    }
  }

  mutating func toggle() {
    switch self {
    case .tree:
      self = .json
    case .json:
      self = .tree
    }
  }
}
