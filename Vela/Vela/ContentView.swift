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
  @State private var editorFontSize: CGFloat = 14

  private var outputText: String {
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
            Button("Parse") {
              _ = try? parser.parse(textFieldContent)
            }
            Button("Clear") {
              textFieldContent = ""
            }
            Button("Restore") {
              textFieldContent = Parser.defaultExampleSource
            }
          }
        }
        .padding(.horizontal)
        .padding(.bottom)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.gray.opacity(0.2))

      Divider() // Optional divider for visual separation

      // Right: TextView (TextEditor)
      VStack {
        TextEditor(text: .constant(outputText))
          .padding()
        HStack {
          Button(outputMode.buttonTitle) {
            outputMode.toggle()
          }
        }
        Spacer()
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
