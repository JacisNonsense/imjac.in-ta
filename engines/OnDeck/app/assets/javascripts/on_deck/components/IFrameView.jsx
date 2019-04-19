class IFrameView extends React.Component {
  render() {
    return <iframe src={this.props.url} frameBorder="0" scrolling="no" height="100%" width="100%" allowFullScreen> </iframe>
  }
}