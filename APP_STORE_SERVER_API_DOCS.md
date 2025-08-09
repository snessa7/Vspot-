# App Store Server API Documentation

## Overview
This document contains essential App Store Server API information for implementing App Store compliance features in macOS applications.

## API Endpoints and Authentication

### JWT Authentication
```json
Header:
{
  "alg": "ES256",
  "kid": "2X9R4HXF34",
  "typ": "JWT"
}

Payload Claims:
{
  "iss": "57246542-96fe-1a63-e053-0824d011072a", // Issuer ID from App Store Connect
  "iat": 1623085200, // Issued At (UNIX time)
  "exp": 1623086400, // Expiration Time (max 60 minutes)
  "aud": "appstoreconnect-v1", // Audience
  "bid": "com.example.testbundleid" // Bundle ID
}
```

### Production vs Sandbox URLs
```
Production: https://api.storekit.itunes.apple.com
Sandbox: https://api.storekit-sandbox.itunes.apple.com
```

## Key Data Types

### App Information
```apidoc
appAppleId (int64): The unique identifier of an app in the App Store
bundleId (string): The bundle identifier of an app
appTransactionId (string): The unique identifier of app download transaction
```

### Product Information
```apidoc
productId (string): Unique identifier of product created in App Store Connect
type (string): Type of In-App Purchase product
  - "Auto-Renewable Subscription"
  - "Non-Consumable" 
  - "Consumable"
  - "Non-Renewing Subscription"
quantity (integer): Number of purchased consumable products
subscriptionGroupIdentifier (string): Identifier of subscription group
```

### User Account Status
```apidoc
userStatus (int32): Customer's account status within app
  0: Account status undeclared
  1: Customer account is active
  2: Customer account is suspended  
  3: Customer account is terminated
  4: Customer account has limited access
```

### Transaction Information
```apidoc
originalTransactionId (string): Original transaction identifier of purchase
webOrderLineItemId (string): Unique identifier of subscription-purchase events
effectiveDate (timestamp): New subscription expiration date for extensions
environment (string): Server environment (sandbox or production)
```

## Rate Limits (Production)

### Endpoint Rate Limits (per second)
```
Get Transaction Info: 50
Get Transaction History: 50
Get All Subscription Statuses: 50
Send Consumption Information: 50
Get Notification History: 50
Extend a Subscription Renewal Date: 20
Look Up Order ID: 10
Get Refund History: 10
Request a Test Notification: 1
Get Test Notification Status: 1

Note: Sandbox environment limits are 10% of production values
```

### Rate Limit Handling
```apidoc
HTTP 429 Response Handling:
- Throttle requests to avoid exceeding per-hour limits
- Implement error handling for RateLimitExceededError
- Check Retry-After header for next request timing
- Log failures and queue for later retry
```

## Common API Endpoints

### Get Transaction Info
```http
GET /inApps/v1/transactions/{transactionId}
```

### Get Transaction History
```http
GET /inApps/v1/history/{originalTransactionId}
```

### Get All Subscription Statuses
```http
GET /inApps/v1/subscriptions/{transactionId}
Parameters:
- transactionId (required): Transaction identifier
- status (optional): Array of subscription status integers
```

### Send Consumption Information
```http
POST /inApps/v1/transactions/{originalTransactionId}/consumption
Content-Type: application/json

Body: ConsumptionRequest object
```

## Error Handling

### Common Error Objects
```apidoc
AccountNotFoundError: App Store account wasn't found
AppNotFoundError: App wasn't found
InvalidAppIdentifierError: Invalid app identifier
InvalidTransactionIdError: Invalid transaction identifier
InvalidStatusError: Status parameter is invalid
RateLimitExceededError: Request exceeded rate limit
GeneralInternalError: General internal error
GeneralInternalRetryableError: Retryable internal error
```

### HTTP Response Codes
```apidoc
200 OK: Request succeeded
400 Bad Request: Invalid request parameters
401 Unauthorized: Invalid JWT in authorization header
404 Not Found: Resource not found
429 Too Many Requests: Rate limit exceeded
500 Internal Server Error: Server error, retry later
```

## Subscription Management

### Extend Subscription Renewal Date
```http
PUT /inApps/v1/subscriptions/extend/{originalTransactionId}
Content-Type: application/json

Body: ExtendRenewalDateRequest
{
  "extendByDays": 7,
  "extendReasonCode": 1,
  "requestIdentifier": "unique-uuid-string"
}
```

### Mass Extend Renewal Dates
```http
POST /inApps/v1/subscriptions/extend/mass
Content-Type: application/json

Body: MassExtendRenewalDateRequest
{
  "requestIdentifier": "unique-uuid-string",
  "extendByDays": 7,
  "extendReasonCode": 1,
  "productId": "com.example.product",
  "storefrontCountryCodes": ["US", "CA", "GB"]
}
```

### Get Extension Status
```http
GET /inApps/v1/subscriptions/extend/mass/{productId}/{requestIdentifier}
```

## Notification Testing

### Request Test Notification
```http
POST /inApps/v1/notifications/test
```

### Get Test Notification Status
```http
GET /inApps/v1/notifications/test/{testNotificationToken}
```

### Get Notification History
```http
GET /inApps/v1/notifications/history
Parameters:
- startDate (optional): Start date in UNIX time (milliseconds)
- endDate (optional): End date in UNIX time (milliseconds)
- notificationType (optional): Notification type filter
- onlyFailures (optional): Boolean for failed notifications only
```

## Advanced Commerce API (v1.14+)

### Advanced Commerce Data Types
```apidoc
advancedCommerceSKU (string): Stock keeping unit identifier
advancedCommercePrice (int64): Price information
advancedCommerceRefundAmount (int64): Refund amount
advancedCommerceRefundDate (timestamp): Date of refund
advancedCommerceTaxCode (string): Tax classification code
advancedCommerceEstimatedTax (int64): Estimated tax amount
```

## Best Practices

### Security
- Store private keys securely
- Use proper JWT token expiration (max 60 minutes)
- Validate all API responses
- Implement proper error handling
- Use HTTPS for all communications

### Performance
- Implement request throttling
- Cache responses when appropriate  
- Use pagination for large datasets
- Retry failed requests with exponential backoff
- Monitor API usage and rate limits

### Data Management
- Store transaction identifiers securely
- Implement proper data retention policies
- Handle subscription state changes promptly
- Maintain audit trails for financial transactions
- Comply with privacy regulations

## App Store Connect Integration

### Required Setup
1. Create App Store Connect API key
2. Download private key file
3. Note Key ID and Issuer ID
4. Configure app bundle identifier
5. Set up App Store Server Notifications URL

### Testing Strategy
- Use sandbox environment for development
- Test all subscription scenarios
- Verify notification handling
- Validate error handling
- Test rate limit scenarios

This documentation provides the foundation for implementing App Store Server API integration in macOS applications for subscription management, transaction validation, and compliance features.
