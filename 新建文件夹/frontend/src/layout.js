import React from 'react';

import { Layout, Menu, Breadcrumb } from 'antd';
import {
  DesktopOutlined,
  PieChartOutlined,
  FileOutlined,
  TeamOutlined,
  UserOutlined,
} from '@ant-design/icons';

import Index from './pages/index';
import QueryPage from './pages/query';
import AddStudent from './pages/add';
import DeleteStudent from './pages/delete';
import EnrollStudent from './pages/enroll';
import DropStudent from './pages/drop';
import CheckClass from './pages/check';


const { Header, Content, Footer, Sider } = Layout;

function getItem(label, key, icon, children) {
  return {
    key,
    icon,
    children,
    label,
  };
}

const queryKeys = new Set(['students', 'courses', 'course_credit', 'classes', 'enrollments', 'score_grade', 'prerequisites', 'logs']);

const items = [
  getItem('Index', 'index', <FileOutlined />),
  getItem('Query', 'query', <DesktopOutlined />, [
    getItem('Students', 'students'),
    getItem('Courses', 'courses'),
    getItem('Course Credits', 'course_credit'),
    getItem('Classes', 'classes'),
    getItem('Enrollments', 'enrollments'),
    getItem('Score', 'score_grade'),
    getItem('Prerequisites', 'prerequisites'),
    getItem('Logs', 'logs'),
    getItem('Check Class', 'check')
  ]),
  getItem('Students', 'stu_menu', <TeamOutlined />, [
    getItem('Delete', 'stu_del'),
    getItem('Enroll', 'enroll'),
    getItem('Drop', 'drop'),
  ]),

];

class SiderDemo extends React.Component {
  state = {
    collapsed: false,
    selectedKey: 'index',
  };
  onCollapse = (collapsed) => {
    console.log(collapsed);
    this.setState({
      collapsed,
    });
  };

  onSelectMenu = ({key}) => {
    this.setState({
      selectedKey: key,
    })
  }

  render() {
    const { collapsed, selectedKey } = this.state;

    let page = <Index />;
    if (queryKeys.has(selectedKey)) {
      page = <QueryPage type={selectedKey}/>;
    }
    else if (selectedKey === 'stu_add') {
      page = <AddStudent/>
    }
    else if (selectedKey === 'stu_del') {
      page = <DeleteStudent/>
    }
    else if (selectedKey === 'enroll') {
      page = <EnrollStudent/>
    }
    else if (selectedKey === 'drop') {
      page = <DropStudent/>
    }
    else if (selectedKey === 'check') {
      page = <CheckClass />
    }
    return (
      <Layout
        style={{
          minHeight: '100vh',
        }}
      >
        <Sider collapsible collapsed={collapsed} onCollapse={this.onCollapse}>
          <div className="logo" />
          <Menu theme="dark" onClick={this.onSelectMenu}
            defaultOpenKeys={['query', 'stu_menu']}
            
            defaultSelectedKeys={[selectedKey]} mode="inline" items={items} />
        </Sider>
        <Layout className="site-layout">
          <Content
            style={{
              margin: 16, display: 'flex', flexDirection: 'column',
            }}
          >

            <div
              className="site-layout-background"
              style={{
                padding: 24,
                minHeight: 360,
                flex: 1,
              }}
            >
              {page}
            </div>
          </Content>

        </Layout>
      </Layout>
    );
  }
}

export default () => <SiderDemo />;