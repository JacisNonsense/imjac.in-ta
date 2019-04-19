class SuggestionsView extends React.Component {
  render() {
    return <div className="flex-row">
      {
        Array.from(this.props.matches)
          .filter(match => { return match.event.key != this.props.currentEvent })
          .map(match => <SuggestedMatch match={match} onSelect={this.props.onSelect} />)
      }
    </div>
  }
}
