class TitleBar extends React.Component {
  render() {
    return <div className="ondeck-top d-flex flex-row">
      <h4> <i className="fas fa-compact-disc">&nbsp;</i> FRC On Deck </h4>  
      <div className="ml-auto" style={{marginTop: '0.3em'}}>
          <h6>{ this.props.watching }&nbsp;&nbsp;<i className="fas fa-tv"></i></h6>
      </div>
    </div>
  }
}