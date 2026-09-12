import { describe, expect, test } from "bun:test"
import { renderHtml, renderPdf, renderTxt, toExportMessages } from "../src/session/export-format"

describe("YogeeshCode export formats", () => {
  const msgs = toExportMessages([
    { info: { role: "user", time: { created: 0 } }, parts: [{ type: "text", text: "hello world" }] },
    {
      info: { role: "assistant", time: { created: 1 } },
      parts: [
        { type: "reasoning", text: "think" },
        { type: "text", text: "hi there" },
        { type: "tool", state: { name: "bash", input: { cmd: "ls" }, output: "src" } },
      ],
    },
  ])

  test("toExportMessages flattens parts", () => {
    expect(msgs).toHaveLength(2)
    expect(msgs[0].text).toContain("hello world")
    expect(msgs[1].text).toContain("hi there")
    expect(msgs[1].text).toContain("[tool bash]")
  })

  test("renderTxt builds transcript", () => {
    const txt = renderTxt("t", "s1", msgs)
    expect(txt).toContain("USER")
    expect(txt).toContain("hello world")
    expect(txt).toContain("ASSISTANT")
    expect(txt).toContain("hi there")
  })

  test("renderHtml is self-contained and escaped", () => {
    const html = renderHtml("t", "s1", [{ role: "user", text: "<script>alert(1)</script>" }])
    expect(html).toContain("<!doctype html>")
    expect(html).toContain("&lt;script&gt;")
    expect(html).not.toContain("<script>alert")
  })

  test("renderPdf produces %PDF with %%EOF", () => {
    const bytes = renderPdf("t", "s1", msgs)
    const head = new TextDecoder().decode(bytes.slice(0, 8))
    const tail = new TextDecoder().decode(bytes.slice(bytes.length - 16))
    expect(msgs.length).toBeGreaterThan(0)
    expect(head).toBe("%PDF-1.4")
    expect(tail).toContain("%%EOF")
  })
})
