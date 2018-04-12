import React from 'react'
import PropTypes from 'prop-types'

const Task = ({id, progress, status, url, output, filecount}) => (
  <tr>
    <th>{id}</th>
    <th>{url}</th>
    <th>{Object.keys(progress).map((i) => (<div key={i}>{i}</div>))}</th>
    <th>{status}</th>
    <th>{output}</th>
    <th>{filecount}</th>
  </tr>
)

export const taskPropTypes = {
  id: PropTypes.number.isRequired,
  progress: PropTypes.object,
  status: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  output: PropTypes.arrayOf(PropTypes.string).isRequired,
  filecount: PropTypes.number.isRequired
};

Task.propTypes = taskPropTypes;

export default Task;
