import React from 'react'
import PropTypes from 'prop-types'
import Task, { taskPropTypes } from './Task'

const Table = ({name, items}) => (
  <div>
  <h2>{name}</h2>
  <table>
  <tbody>
  {items.map((item) => (
            <Task key={item.id} id={item.id}
                  progress={item.progress}
                  status={item.status}
                  url={item.url}
                  output={item.output}
                  filecount={item.filecount}/>
          )
        )}
      </tbody>
    </table>
  </div>
)

export const tablePropTypes = {
  name: PropTypes.string.isRequired,
  items: PropTypes.arrayOf(PropTypes.shape(taskPropTypes).isRequired).isRequired
};

Table.propTypes = tablePropTypes;

export default Table;
