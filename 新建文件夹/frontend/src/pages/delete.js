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


function DeleteStudent() {
    const onFinish = async (values) => {
        const res = await fetch(`/api?action=delete&bno=${values['B#']}`, {method: 'POST'});
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
            
           
            <Form.Item wrapperCol={{ ...layout.wrapperCol, offset: 8 }}>
                <Button type="danger" htmlType="submit">
                    Delete
                </Button>
            </Form.Item>
        </Form>
    );
};

export default DeleteStudent;