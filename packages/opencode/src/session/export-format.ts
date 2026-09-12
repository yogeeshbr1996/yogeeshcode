// YogeeshCode: transcript render helpers, no external deps.
export type ExportFormat = "json" | "txt" | "html" | "pdf"
export type ExportMessage = { role: string; time?: number; text: string }
export function escHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}
export function partText(part: any): string {
  if (!part || typeof part !== "object") return ""
  if (part.type === "text" || part.type === "reasoning") {
    return typeof part.text === "string" ? part.text : ""
  }
  if (part.type === "tool") {
    const st = part.state ?? {}
    const nm = st.name ?? "tool"
    let s = "[tool " + nm + "]"
    if (st.input !== undefined) s += "\ninput: " + JSON.stringify(st.input).slice(0, 2000)
    if (typeof st.output === "string") s += "\noutput:\n" + st.output.slice(0, 4000)
    if (typeof st.error === "string") s += "\nerror: " + st.error.slice(0, 1000)
    return s
  }
  if (part.type === "file") return "[file " + (part.filename ?? part.url ?? "") + "]"
  if (part.type === "step-finish") return part.reason ? "[" + part.reason + "]" : ""
  if (part.type === "patch") return "[patch " + (part.files ?? []).length + " files]"
  return ""
}
export function toExportMessages(messages: any[]): ExportMessage[] {
  const out: ExportMessage[] = []
  for (const msg of messages ?? []) {
    const role = msg?.info?.role ?? "unknown"
    const time = msg?.info?.time?.created
    const texts: string[] = []
    for (const part of msg?.parts ?? []) {
      const t = partText(part)
      if (t.trim()) texts.push(t)
    }
    if (texts.length) out.push({ role, time, text: texts.join("\n\n") })
  }
  return out
}
export function renderTxt(title: string, sid: string, msgs: ExportMessage[]): string {
  const lines = ["YogeeshCode export", "Session: " + title + " (" + sid + ")", "Exported: " + new Date().toISOString(), ""]
  for (const m of msgs) {
    const when = m.time ? new Date(m.time).toLocaleString() : ""
    lines.push("=== " + m.role.toUpperCase() + " " + when + " ===", m.text, "")
  }
  return lines.join("\n")
}
export function renderHtml(title: string, sid: string, msgs: ExportMessage[]): string {
  const bubbles = msgs
    .map((m) => {
      const cls = m.role === "user" ? "user" : "assistant"
      const when = m.time ? new Date(m.time).toLocaleString() : ""
      return '<div class="msg ' + cls + '"><div class="meta">' + escHtml(m.role + " " + when) + "</div><pre>" + escHtml(m.text) + "</pre></div>"
    })
    .join("\n")
  return '<!doctype html><html><head><meta charset="utf-8"><title>' + escHtml(title) + "</title><style>body{font-family:system-ui,sans-serif;max-width:860px;margin:24px auto;padding:0 16px}h1{font-size:20px}.sub{color:#666;font-size:12px}.msg{border:1px solid #ddd;border-radius:8px;padding:12px;margin:12px 0}.msg.user{background:#f0f6ff}.msg.assistant{background:#fafafa}.meta{font-size:11px;color:#888}pre{white-space:pre-wrap;font-size:13px}@media print{.msg{break-inside:avoid}}</style></head><body><h1>" + escHtml(title) + '</h1><div class="sub">YogeeshCode export ' + escHtml(sid) + " - print to PDF from browser for best layout</div>" + bubbles + "</body></html>"
}
export function renderPdf(title: string, sid: string, msgs: ExportMessage[]): Uint8Array {
  const raw = renderTxt(title, sid, msgs)
  const lines: string[] = []
  for (const paragraph of raw.split("\n")) {
    let line = paragraph
    while (line.length > 95) {
      let cut = line.lastIndexOf(" ", 95)
      if (cut < 20) cut = 95
      lines.push(line.slice(0, cut))
      line = line.slice(cut).trimStart()
    }
    lines.push(line)
  }
  const esc = (s: string) => s.replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)")
  const perPage = 68
  const pages: string[][] = []
  for (let i = 0; i < lines.length; i += perPage) pages.push(lines.slice(i, i + perPage))
  if (pages.length === 0) pages.push(["(empty)"])
  const pageCount = pages.length
  const pageNums: number[] = []
  const contentNums: number[] = []
  let nxt = 3
  for (let i = 0; i < pageCount; i++) {
    pageNums.push(nxt++)
    contentNums.push(nxt++)
  }
  const objs: string[] = []
  objs[1] = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
  objs[2] = "2 0 obj\n<< /Type /Pages /Kids [" + pageNums.map((n) => n + " 0 R").join(" ") + "] /Count " + pageCount + " >>\nendobj\n"
  for (let i = 0; i < pageCount; i++) {
    const tl = pages[i].map((l, j) => "BT /F1 9 Tf 40 " + (800 - j * 10.5) + " Td (" + esc(l) + ") Tj ET").join("\n")
    objs[pageNums[i]] = pageNums[i] + " 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 " + nxt + " 0 R >> >> /Contents " + contentNums[i] + " 0 R >>\nendobj\n"
    objs[contentNums[i]] = contentNums[i] + " 0 obj\n<< /Length " + tl.length + " >>\nstream\n" + tl + "\nendstream\nendobj\n"
  }
  objs[nxt] = nxt + " 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"
  const header = "%PDF-1.4\n"
  let offset = header.length
  const offsets: number[] = [0]
  let body = ""
  for (let n = 1; n <= nxt; n++) {
    offsets[n] = offset
    body += objs[n]
    offset += objs[n].length
  }
  let xref = "xref\n0 " + (nxt + 1) + "\n0000000000 65535 f \n"
  for (let n = 1; n <= nxt; n++) xref += String(offsets[n]).padStart(10, "0") + " 00000 n \n"
  const trailer = "trailer\n<< /Size " + (nxt + 1) + " /Root 1 0 R >>\nstartxref\n" + offset + "\n%%EOF"
  return new TextEncoder().encode(header + body + xref + trailer)
}
