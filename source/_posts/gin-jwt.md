---
title: gin & jwt
date: 2024-01-26 20:06:36
author: ivhu
categories:
  - 编程
  - go

tags:
  - gin
  - jwt
---

作用

JWT 的主要作用是方便客戶端與伺服器之間的身份驗證。 使用JWT 可以在不需要每次登入的情況下，在客戶端與伺服器之間安全地傳遞封裝身份信息。 它還可以用於許多其他用途，例如串接多個服務，並將數據在服務間安全地傳遞。

简单类说jwt作用在c/s模型中的通信过程中，用于验证c端是否具有访问权限。

一般在jwt中包含一些基本信息，包括用户名，时间戳等。可以在一定承担上防止重放攻击。

注意：自jwt的内容部分，切勿包含任何如密码等敏感信息，因为jwt是使用明文传递的。

在jwt中需要双发线下协商一个所secret，在之后的请求中c端将使用这个secret最jwt做签名，服务端使用这个secret验证签名，签名的内容明文传输。
在gin中使用jwt

gin可以使用中间件的形式完成jwt校验

```go
// node config group
nodeGroup := router.Group(methods.NodeTag, methods.JWTMiddleware())
initNodeConfigControllers(nodeGroup)

```

以上是在 NodeTag 这个请求组里面添加JWT校验，这样只作用与这一个请求组，也可以针对某个请求做校验或全部请求都做校验。

> 注意，一般将JWT的token放在请求头里面，不要放在请求体里面

JWT校验函数一般格式

```go
func JWTMiddleware() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		user_token := ctx.GetHeader("Authorization")
		token, err := jwt.Parse(user_token, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(configuration.GetToken()), nil // 此处GetToken得到的就是双发协定好的secret
		})
		if err != nil {
			log.Error("Token parsing error", "err", err)
			ReturnErrorResp(ctx, http.StatusUnauthorized, PermissionError, err.Error())
			ctx.Abort()
			return
		}

		// 验证解析后的令牌是否有效
		if !token.Valid {
			log.Error("Invalid token")
			ReturnErrorResp(ctx, http.StatusUnauthorized, PermissionError, "token is ill")
			ctx.Abort()
			return
		} else {
			// 从令牌中提取有效载荷 (claims)
			claims, ok := token.Claims.(jwt.MapClaims)
			if ok {
				if !claims.VerifyExpiresAt(time.Now().Unix(), true) {
					log.Error("jwt token timeout")
					ReturnErrorResp(ctx, http.StatusUnauthorized, PermissionError, "token is ill")
					ctx.Abort()
					return
				}
			} else {
				log.Error("Invalid token claims")
				ReturnErrorResp(ctx, http.StatusUnauthorized, PermissionError, "token is ill")
				ctx.Abort()
				return
			}
		}
		ctx.Next()
	}
}
```
