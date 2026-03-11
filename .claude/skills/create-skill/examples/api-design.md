# 示例 Skill: API 设计规范（背景知识型）

```yaml
---
name: api-design-guidelines
description: RESTful API 设计规范和最佳实践。在设计 API、创建端点、编写 API 文档时应用这些规范。
user-invocable: false
---

# API 设计规范

## URL 设计

### 资源命名
- 使用名词复数形式: `/users`, `/orders`, `/products`
- 使用 kebab-case: `/user-profiles`, `/order-items`
- 避免动词: ❌ `/getUsers` ✅ `/users`

### 层级关系
```
GET    /users/{id}/orders          # 获取用户的订单
POST   /users/{id}/orders          # 为用户创建订单
GET    /users/{id}/orders/{orderId} # 获取特定订单
```

## HTTP 方法

| 方法 | 用途 | 幂等性 |
|------|------|--------|
| GET | 获取资源 | ✅ |
| POST | 创建资源 | ❌ |
| PUT | 完整更新资源 | ✅ |
| PATCH | 部分更新资源 | ❌ |
| DELETE | 删除资源 | ✅ |

## 状态码

### 成功
- `200 OK` - 成功获取/更新
- `201 Created` - 成功创建
- `204 No Content` - 成功删除

### 客户端错误
- `400 Bad Request` - 请求格式错误
- `401 Unauthorized` - 未认证
- `403 Forbidden` - 无权限
- `404 Not Found` - 资源不存在
- `422 Unprocessable Entity` - 验证失败

### 服务端错误
- `500 Internal Server Error` - 服务器错误
- `503 Service Unavailable` - 服务不可用

## 响应格式

### 成功响应
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100
  }
}
```

### 错误响应
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  }
}
```

## 分页

使用 query 参数：
```
GET /users?page=2&per_page=20
GET /users?offset=20&limit=20
```

## 版本控制

推荐使用 URL 前缀：
```
/api/v1/users
/api/v2/users
```
```
