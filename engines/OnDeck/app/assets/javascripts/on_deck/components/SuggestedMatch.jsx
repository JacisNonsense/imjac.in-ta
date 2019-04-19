class SuggestedMatch extends React.Component {
  constructor(props) {
    super(props)
    this.onSelect = this.onSelect.bind(this)
    this.state = { happens_in: 'xxx' }
  }

  onSelect(e) {
    e.preventDefault()
    this.props.onSelect(this.props.match)
  }

  componentDidMount() {
    setInterval(() => {
      var now = Math.round((new Date()).getTime() / 1000)
      var delta = this.props.match.match.predicted_time - now;
      var unit = "sec"

      if (Math.abs(delta) > 60) {
        delta = Math.floor(delta / 60)
        unit = "min"
      }
      this.setState({ happens_in: delta + " " + unit + (delta < 0 ? " (Delayed)" : "") })
    }, 1000)
  }

  render() {
    return <div className="match-suggestion flex-fill" onClick={this.onSelect}>
      <strong> {this.props.match.match_name} @ {this.props.match.event.short_name}</strong>
      <i> Predicted in: { this.state.happens_in } { this.props.match.last_played == null ? "" : ("- Last Match " + this.props.match.last_played) } </i>
      <Alliance color="blue" teams={this.props.match.blue.teams} />
      <Alliance color="red" teams={this.props.match.red.teams} />
    </div>
  }
}

class Alliance extends React.Component {
  render() {
    return <div className={"alliance flex-row " + this.props.color}>
      {
        Array.from(this.props.teams).map(team => {
          return <Team number={team.number} gds={team.gds} pps={team.pps}/>
        })
      }
    </div>
  }
}

const pps_desc = "Past Performance Score (PPS) - Aggregate of how well this team has done this season";
const gds_desc = "Global Dominance Score (GDS) - Aggregate of how well this team is doing against amongst all events live right now";

const pps_gold_thresh = 80;
const gds_gold_thresh = 18;

class Team extends React.Component {
  componentDidMount() {
    $('[data-toggle="tooltip"]').tooltip();
  }

  componentDidUpdate() {
    $('[data-toggle="tooltip"]').tooltip();
  }

  render() {
    return <div className="team flex-fill">
      <strong className={ this.props.pps >= pps_gold_thresh || this.props.gds >= gds_gold_thresh ? "hot-team" : "" }>{this.props.number}</strong>
      <p>
        <span className={"pps " + (this.props.pps >= pps_gold_thresh ? "hot-team" : "")} data-toggle="tooltip" data-placement="top" title={pps_desc}><i className="fas fa-history"></i> {this.props.pps}</span>
        &nbsp;|&nbsp;
        <span className={"gds " + (this.props.gds >= gds_gold_thresh ? "hot-team": "")} data-toggle="tooltip" data-placement="top" title={gds_desc}>{this.props.gds}<i className="fas fa-bolt"></i></span>
      </p>
    </div>
  }
}