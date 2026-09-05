import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  format({ params: { style } }) {
    const input = this.inputTarget
    const start = input.selectionStart
    const end = input.selectionEnd
    const selected = input.value.slice(start, end)
    const formats = {
      bold: ["**", "**", "Bold text"],
      italic: ["_", "_", "Italic text"],
      heading: ["# ", "", "Heading"],
      link: ["[", "](https://)", "Link text"]
    }

    let replacement
    let selectionStart
    let selectionEnd

    if (style === "list") {
      const content = selected || "List item"
      replacement = content.split("\n").map((line) => `- ${line}`).join("\n")
      selectionStart = start + 2
      selectionEnd = start + replacement.length
    } else {
      const [before, after, placeholder] = formats[style]
      const content = selected || placeholder
      replacement = `${before}${content}${after}`
      selectionStart = start + before.length
      selectionEnd = selectionStart + content.length
    }

    input.setRangeText(replacement, start, end, "end")
    input.focus()
    input.setSelectionRange(selectionStart, selectionEnd)
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
