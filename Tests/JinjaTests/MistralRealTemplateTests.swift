import Testing
import Foundation
@testable import Jinja

/// Verifies for-loop iterable accepts arbitrary expressions (not only
/// names + filters). Real-world repro: Mistral-Medium-3.5 chat
/// template uses `{%- for message in loop_messages + [{...}] %}`
/// which `parseFilter()` rejected with "Expected '%}' after for
/// loop.. Got plus instead". Fix at Parser.swift:186 swaps to
/// parseExpression().
@Test func forLoopIterableAcceptsBinaryPlus() throws {
    let src = """
{%- set base = ["a", "b"] -%}
{%- for x in base + ["c"] -%}{{- x -}}{%- endfor -%}
"""
    let tmpl = try Template(src)
    let out = try tmpl.render([:])
    #expect(out == "abc")
}

@Test func mistral3RealNativeTemplateParses() throws {
    // Inline a minimum repro of the mistral3 construct so this test
    // doesn't depend on a bundle being on disk.
    let src = """
{%- set loop_messages = messages -%}
{%- for message in loop_messages + [{'role': '__sentinel__'}] -%}
  {%- if message.role != '__sentinel__' -%}
    {{- '[INST]' -}}{{- message.content -}}{{- '[/INST]' -}}
  {%- endif -%}
{%- endfor -%}
"""
    let tmpl = try Template(src)
    let out = try tmpl.render(["messages": [["role": "user", "content": "Hi"]]])
    #expect(out == "[INST]Hi[/INST]")
}
