class FRCOnDeck extends React.Component {
  constructor(props) {
    super(props)
    this.state = { matches: [], hide: false, channel: 'firstinspires1', currentMatch: null }

    this.fetcher = new Fetcher("api/recommendations.json", [])
    this.fetcher.mount(data => this.setState({ matches: data }))

    setInterval(() => { this.fetcher.refresh() }, 60*1000)   // Update every minute

    this.updateWebcast = this.updateWebcast.bind(this)
    this.toggleHide = this.toggleHide.bind(this)
  }

  toggleHide(e) {
    this.setState({hide: !this.state.hide});
    e.preventDefault()
  }

  updateWebcast(match) {
    console.log("Selected Match: ")
    console.log(match)
    this.setState({ currentMatch: match, channel: match.event.webcasts[0].channel })
  }

  render() {
    return <div className="flex-column ondeck-container">
      <div className="title-window">
        <TitleBar watching={ this.state.currentMatch == null ? 'firstinspires1' : this.state.currentMatch.event.short_name } />
      </div>

      <div className="player-window flex-grow-1">
        <TwitchView channel={this.state.channel} />
      </div>

      <div className="suggestions-window">
        <div className={"hide-bar"} onClick={this.toggleHide}> 
          <span>
            <i className={"fas fa-chevron-" + (this.state.hide ? 'up' : 'down')}></i> &nbsp;
          </span>
        </div>
        <div className={ "hideable " + ((this.state.matches.length == 0 || this.state.hide) ? "hide" : "visible") }>
          <SuggestionsView currentEvent={ this.state.currentMatch == null ? null : this.state.currentMatch.event.key } matches={ this.state.matches } onSelect={this.updateWebcast}/>
        </div>
      </div>
    </div>
  }
}