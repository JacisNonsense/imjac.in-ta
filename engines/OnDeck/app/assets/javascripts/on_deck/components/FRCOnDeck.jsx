class FRCOnDeck extends React.Component {
  constructor(props) {
    super(props)
    this.state = { matches: [], hide: false, channel: 'firstinspires1', currentMatch: null }

    this.fetcher = new Fetcher(this.props.rec_url, [])
    this.fetcher.mount(data => this.setState({ matches: data }))

    setInterval(() => { this.fetcher.refresh() }, 15*1000)   // Update every 15s

    this.updateWebcast = this.updateWebcast.bind(this)
    this.toggleHide = this.toggleHide.bind(this)
    this.setHome = this.setHome.bind(this)
  }

  setHome(e) {
    this.setState({ currentMatch: null, channel: 'firstinspires1' })
    e.preventDefault()
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
        <TitleBar watching={ this.state.currentMatch == null ? 'firstinspires1' : this.state.currentMatch.event.short_name } onHome={ this.setHome } />
      </div>

      <div className="player-window flex-grow-1">
        <div className="d-flex flex-row">
          <IFrameView url={"https://player.twitch.tv/?channel=" + this.state.channel} />
          <div className="chat-window">
            <IFrameView url={"https://twitch.tv/embed/firstupdatesnow/chat"} />
          </div>
        </div>
      </div>

      <div className="suggestions-window">
        <div className={"hide-bar"} onClick={this.toggleHide}> 
          <span>
            <i className={"fas fa-chevron-" + (this.state.hide ? 'up' : 'down')}></i> Hot Matches &nbsp;
          </span>
        </div>
        <div className={ "hideable " + ((this.state.matches.length == 0 || this.state.hide) ? "hide" : "visible") }>
          <SuggestionsView currentEvent={ this.state.currentMatch == null ? null : this.state.currentMatch.event.key } matches={ this.state.matches } onSelect={this.updateWebcast}/>
        </div>
      </div>
    </div>
  }
}