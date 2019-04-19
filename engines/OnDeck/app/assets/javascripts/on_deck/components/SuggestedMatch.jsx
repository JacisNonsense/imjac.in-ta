class SuggestedMatch extends React.Component {
  constructor(props) {
    super(props)
    this.onSelect = this.onSelect.bind(this)
  }

  onSelect(e) {
    e.preventDefault()
    this.props.onSelect(this.props.match)
  }

  render() {
    return <div className="match-suggestion flex-fill" onClick={this.onSelect}>
      <strong className="match-name"> {this.props.match.match_name} @ {this.props.match.event.short_name}</strong>
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
const gds_desc = "Global Dominance Score (GDS) - Aggregate of how well this team has done against all other events live now";

class Team extends React.Component {
  componentDidMount() {
    $('[data-toggle="tooltip"]').tooltip();
  }

  componentDidUpdate() {
    $('[data-toggle="tooltip"]').tooltip();
  }

  render() {
    return <div className="team flex-fill">
      <strong>{this.props.number}</strong>
      <p>
        <span className="pps" data-toggle="tooltip" data-placement="top" title={pps_desc}><i className="fas fa-history"></i> {this.props.pps}</span>
        &nbsp;|&nbsp;
        <span className="gds" data-toggle="tooltip" data-placement="top" title={gds_desc}>{this.props.gds} <i className="fas fa-bolt"></i></span>
      </p>
    </div>
  }
}