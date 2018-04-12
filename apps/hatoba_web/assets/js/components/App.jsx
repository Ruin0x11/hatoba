import React from 'react'
import Table from './Table'

class App extends React.Component {
  constructor(props) {
    super(props)

    this.state = {}
  }

  componentDidMount() {
    // this.ws = new WebSocket("localhost:8081")
    // this.ws.onmessage = e => this.setState({ users: Object.values(JSON.parse(e.data)) })
    // this.ws.onerror = e => this.setState({ error: 'WebSocket error' })
    // this.ws.onclose = e => !e.wasClean && this.setState({ error: `WebSocket error: ${e.code} ${e.reason}` })
  }

  componentWillUnmount() {
    // this.ws.close()
  }

  render() {
    const items = [
      {id: 1, progress: {"a": "50.0"}, status: "started", url: "https://www.example.com", output: ["a", "b"], filecount: 1},
      {id: 2, progress: {"b": "50.0"}, status: "started", url: "https://www.example.com", output: ["a", "b"], filecount: 1},
      {id: 3, progress: {"a": "50.0", "b": "40.0"}, status: "started", url: "https://www.example.com", output: ["a", "b"], filecount: 1}
    ]
    return (
      <div>
        <Table name="Downloading" items={items}/>
        <Table name="Uploading" items={items}/>
        <Table name="Finished" items={items}/>
      </div>
    )
  }
}

export default App
