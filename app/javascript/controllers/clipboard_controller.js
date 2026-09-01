import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  select() {
    this.sourceTarget.select()
  }

  // navigator.clipboard only exists in a secure context, which an Errbit
  // served over plain http is not, so fall back to copying the selection.
  async copy() {
    this.select()

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
    } catch {
      document.execCommand("copy")
    }
  }
}
