class TwitchView extends React.Component {
  render() {
    return <iframe src={"https://player.twitch.tv/?channel=" + this.props.channel} frameBorder="0" scrolling="no" height="100%" width="100%" allowFullScreen> </iframe>
  }
}