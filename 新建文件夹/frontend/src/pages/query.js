import React, { useState, useEffect } from 'react';
import { Empty, Table } from 'antd';



export default function QueryPage(props) {
    const [columns, setColumns] = useState([]);
    const [data, setData] = useState([]);

    useEffect(() => {
        async function load() {
            const res = await fetch(`/api?action=query&table=${props.type}`, {method: 'POST'});
            const json = await res.json();
            setData(json.map((json,idx) => ({...json, key: idx})));
            setColumns(Object.keys(json[0] || {}).map(key => ({title: key, dataIndex: key, key})));
        }
        load();
    }, [props.type]);
    if (data.length === 0) {
        return (
            <Empty/>
        )
    }
    else {
        return (
            <div>
                <Table dataSource={data} columns={columns} />
            </div>
        )
    }
    
}