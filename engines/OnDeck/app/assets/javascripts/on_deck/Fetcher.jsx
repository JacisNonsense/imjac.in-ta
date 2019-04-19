class Fetcher {
  constructor(url, initial_data) {
    this.url = url
    this.callbacks = []
    this.data = initial_data
  }

  refresh() {
    console.log("Updating: " + this.url)
    fetch(this.url).then(response => response.json()).then(data => this.onData(data))
  }

  onData(data) {
    this.data = data
    this.callbacks.forEach(cb => { cb(data) })
  }

  mount(cb) {
    this.callbacks.push(cb)
    this.refresh()
  }
}