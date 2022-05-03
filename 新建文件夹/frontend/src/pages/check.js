import React, { useState } from 'react';

import { Form, Input, Button, Modal, Table, Empty } from 'antd';
const layout = {
    labelCol: {
        span: 8,
    },
    wrapperCol: {
        span: 16,
    },
};


function CheckClass() {
    const [columns, setColumns] = useState([]);
    const [data, setData] = useState([]);
    const onFinish = async (values) => {
        const res = await fetch(`/api?action=check&classid=${values['classid']}`, {method: 'POST'});
        const json = await res.json();
        setData(json.map((json,idx) => ({...json, key: idx})));
        setColumns(Object.keys(json[0] || {}).map(key => ({title: key, dataIndex: key, key})));
    };

    return (
        <div>
            <Form {...layout} style={{margin: '0 auto', width: 320}} onFinish={onFinish}>
                <Form.Item
                    name={['classid']}
                    label="Class ID"
                    rules={[
                        {
                            required: true,
                        },
                    ]}
                >
                    <Input />
                </Form.Item>
                
            
                <Form.Item wrapperCol={{ ...layout.wrapperCol, offset: 8 }}>
                    <Button type="primary" htmlType="submit">
                        Check Class
                    </Button>
                </Form.Item>
            </Form>
            <div>
                {data.length === 0 ? <Empty/> : <Table dataSource={data} columns={columns} />}
            </div>
        </div>
        
    );
};

export default CheckClass;