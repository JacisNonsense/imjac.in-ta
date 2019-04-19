class TitleBar extends React.Component {
  render() {
    return <div className="ondeck-top d-flex flex-row">
      <h4> <i className="fas fa-compact-disc">&nbsp;</i> FRC On Deck </h4>  
      <div className="ml-auto" style={{marginTop: '0.3em'}}>
          <span>
            <h6>
              { this.props.watching }&nbsp;&nbsp;<i className="fas fa-tv"></i> &nbsp; &nbsp;
              <i style={{cursor: 'pointer'}} onClick={ this.props.onHome } className="fas fa-home"></i> 
            </h6>
          </span>
      </div>
    </div>
  }
}