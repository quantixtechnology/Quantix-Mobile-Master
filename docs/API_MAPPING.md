# API Mapping — Quantix Core ↔ Mobile

Base URL: `https://api.quantix.app/v1`  
All authenticated requests carry: `Authorization: Bearer <accessToken>` and `X-Business-ID: <businessId>`

---

## Authentication

| Method | Endpoint | Body | Response | Consumer |
|---|---|---|---|---|
| POST | `/auth/otp/request` | `{phone, businessId}` | `{sessionToken}` | Customer |
| POST | `/auth/otp/verify` | `{sessionToken, code}` | `{accessToken, refreshToken, user}` | Customer |
| POST | `/auth/login` | `{email, password, role, businessId}` | `{accessToken, refreshToken, user}` | Rider, Admin |
| POST | `/auth/refresh` | `{refreshToken}` | `{accessToken, refreshToken}` | All |
| POST | `/auth/logout` | — | `{}` | All |
| GET | `/auth/me` | — | `{user}` | All |

### `user` object

```json
{
  "id":         "usr_abc123",
  "name":       "Ahmed Khan",
  "phone":      "+92-300-1234567",
  "email":      "ahmed@example.com",
  "role":       "customer | rider | admin",
  "businessId": "QTX001"
}
```

### Mobile auth flow

```
Customer:
  loginScreen  →  POST /auth/otp/request  →  otpScreen
  otpScreen    →  POST /auth/otp/verify   →  homeScreen
  (token stored in FlutterSecureStorage; restored on next launch via GET /auth/me)

Rider / Admin:
  loginScreen  →  POST /auth/login        →  ordersScreen / dashboardScreen
```

---

## Tenant / Business

| Method | Endpoint | Body | Response | Consumer |
|---|---|---|---|---|
| GET | `/tenant` | — | `{BrandConfig}` | All (fallback — normally loaded from bundled config.json) |
| GET | `/tenant/config` | — | `{apiConfig, features, limits}` | All |

### Mobile usage

Tenant config is primarily loaded from the bundled `branding/{flavor}/config.json` at startup. The API endpoint is a fallback for dynamic feature flag updates without a rebuild.

---

## Catalog

| Method | Endpoint | Query / Body | Response | Consumer |
|---|---|---|---|---|
| GET | `/categories` | — | `[{id, name, image, parentId}]` | Customer |
| GET | `/products` | `?category=&search=&page=&limit=` | `{items: [{product}], total, page}` | Customer |
| GET | `/products/:id` | — | `{product}` | Customer |

### `product` object

```json
{
  "id":          "prd_xyz",
  "name":        "Product Name",
  "description": "...",
  "price":       150.00,
  "currency":    "PKR",
  "image":       "https://cdn.quantix.app/...",
  "category":    "cat_abc",
  "inStock":     true,
  "stock":       42
}
```

---

## Cart & Orders

| Method | Endpoint | Body | Response | Consumer |
|---|---|---|---|---|
| POST | `/orders` | `{items:[{productId,qty}], addressId, paymentMethod}` | `{order}` | Customer |
| GET | `/orders` | `?status=&page=` | `{items:[{order}], total}` | Customer |
| GET | `/orders/:id` | — | `{order}` | Customer, Admin |
| PATCH | `/orders/:id/cancel` | `{reason}` | `{order}` | Customer |

### `order` object

```json
{
  "id":        "ord_001",
  "status":    "pending | confirmed | preparing | dispatched | delivered | cancelled",
  "items":     [{...}],
  "total":     450.00,
  "address":   {...},
  "rider":     {...},
  "createdAt": "2026-05-25T10:00:00Z",
  "eta":       "2026-05-25T10:30:00Z"
}
```

---

## Delivery (Rider)

| Method | Endpoint | Body | Response | Consumer |
|---|---|---|---|---|
| GET | `/deliveries/assigned` | — | `[{order}]` | Rider |
| GET | `/deliveries/:id` | — | `{order, route}` | Rider |
| PATCH | `/deliveries/:id/status` | `{status, location:{lat,lng}}` | `{delivery}` | Rider |
| POST | `/deliveries/:id/location` | `{lat, lng, heading}` | `{}` | Rider |

### Delivery status flow

```
assigned → picked_up → en_route → delivered
```

---

## Tracking (Customer real-time)

WebSocket: `wss://api.quantix.app`  
Auth: `Authorization: Bearer <token>` header on connect

| Event | Direction | Payload | Consumer |
|---|---|---|---|
| `tracking:subscribe` | Client → Server | `{orderId}` | Customer |
| `delivery:location_updated` | Server → Client | `{lat, lng, heading, riderId}` | Customer |
| `tracking:eta_updated` | Server → Client | `{orderId, eta}` | Customer |
| `order:status_changed` | Server → Client | `{orderId, status}` | Customer, Admin |
| `notification:new` | Server → Client | `{title, body, type, data}` | All |

---

## Admin

| Method | Endpoint | Query | Response | Consumer |
|---|---|---|---|---|
| GET | `/admin/stats` | `?date=` | `{todayOrders, revenue, activeRiders, pendingOrders}` | Admin |
| GET | `/admin/orders` | `?status=&page=&search=` | `{items:[{order}], total}` | Admin |
| PATCH | `/admin/orders/:id/status` | `{status}` | `{order}` | Admin |
| GET | `/admin/customers` | `?page=&search=` | `{items:[{user}], total}` | Admin |
| GET | `/admin/inventory` | `?category=&lowStock=` | `{items:[{product, stock}]}` | Admin |
| PATCH | `/admin/inventory/:id` | `{stock, price}` | `{product}` | Admin |
| GET | `/admin/riders` | `?active=` | `[{rider, location, activeOrder}]` | Admin |

---

## Profile & Addresses

| Method | Endpoint | Body | Response | Consumer |
|---|---|---|---|---|
| GET | `/profile` | — | `{user}` | Customer, Rider |
| PATCH | `/profile` | `{name, email}` | `{user}` | Customer |
| GET | `/addresses` | — | `[{address}]` | Customer |
| POST | `/addresses` | `{label, line1, city, lat, lng}` | `{address}` | Customer |
| DELETE | `/addresses/:id` | — | `{}` | Customer |

---

## Earnings (Rider)

| Method | Endpoint | Query | Response | Consumer |
|---|---|---|---|---|
| GET | `/earnings` | `?period=today\|week\|month` | `{total, deliveries, breakdown:[{date,amount}]}` | Rider |
| GET | `/earnings/history` | `?page=` | `{items:[{delivery, amount}]}` | Rider |

---

## Error response format

```json
{
  "error":   "VALIDATION_ERROR | UNAUTHORIZED | NOT_FOUND | SERVER_ERROR",
  "message": "Human-readable description",
  "field":   "phone"
}
```

HTTP status codes:
- `400` — bad request / validation
- `401` — unauthorized (token expired or missing)
- `403` — forbidden (wrong role or tenant)
- `404` — not found
- `422` — validation error
- `5xx` — server error

Mobile SDK maps these to: `NetworkException`, `UnauthorizedException`, `ValidationException`, `ServerException`, `TenantException`.

---

## Tenant boot sequence (mobile)

```
App launch
    │
    ├─ BrandLoader.load(appFlavor)          // reads branding/{flavor}/config.json
    │       └─ sets: appName, colors, features, businessId, currency
    │
    ├─ ProviderScope override: brandConfigProvider = brandConfig
    │       └─ ApiClient gets tenantId = brandConfig.businessId
    │           └─ every request: X-Business-ID: {businessId}
    │
    ├─ SplashScreen mounts
    │       └─ AuthNotifier.restoreSession()
    │               └─ SecureStorage.getToken()  →  GET /auth/me  →  UserModel
    │
    ├─ isAuthenticated=true  →  /home | /orders | /dashboard
    └─ isAuthenticated=false →  /login
```
