import React from 'react';

import { Form, Input, Button, Modal } from 'antd';
const layout = {
    labelCol: {
        span: 8,
    },
    wrapperCol: {
        span: 16,
    },
};


function DropStudent() {
    const onFinish = async (values) => {
        const res = await fetch(`/api?action=drop&bno=${values['B#']}&classid=${values['classid']}`, {method: 'POST'});
        const json = await res.json();
        if (json.code === 0) {
            Modal.info({content: 'done'});
        }
        else {
            Modal.error({content: json.errMsg  || 'Error'});
        }
    };

    return (
        <Form {...layout} style={{margin: '0 auto', width: 320}} onFinish={onFinish}>
            <Form.Item
                name={['B#']}
                label="B#"
                rules={[
                    {
                        required: true,
                    },
                ]}
            >
                <Input />
            </Form.Item>
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
                    Drop
                </Button>
            </Form.Item>
        </Form>
    );
};

export default DropStudent;