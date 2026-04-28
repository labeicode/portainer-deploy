// MongoDB 初始化脚本示例
// 此目录下的 .js 文件会在首次启动时自动执行

// 切换到 admin 数据库
// db = db.getSiblingDB('admin');

// 创建管理员用户
// db.createUser({
//   user: 'admin',
//   pwd: 'admin123',
//   roles: [{ role: 'root', db: 'admin' }]
// });

// 切换到业务数据库
// db = db.getSiblingDB('mydb');

// 创建业务用户
// db.createUser({
//   user: 'myuser',
//   pwd: 'mypassword',
//   roles: [{ role: 'readWrite', db: 'mydb' }]
// });

// 创建示例集合
// db.createCollection('users');

// 插入示例数据
// db.users.insertOne({
//   name: 'John Doe',
//   email: 'john@example.com',
//   createdAt: new Date()
// });

print('MongoDB initialization completed');
