# New TeraAPI Endpoints

## Rate Limiting & Encryption

### POST /api/stream/encrypt-gcm
Encrypt plaintext using AES-GCM-256

**Request:**
```json
{
  "plaintext": "sensitive data",
  "aesKey": "base64_encoded_32_byte_key"
}
```

**Response:**
```json
{
  "ciphertext": "base64_encoded_ciphertext",
  "iv": "base64_encoded_12_byte_iv"
}
```

### POST /api/stream/decrypt-gcm
Decrypt AES-GCM encrypted data

**Request:**
```json
{
  "ciphertext": "base64_ciphertext",
  "iv": "base64_iv",
  "aesKey": "base64_encoded_32_byte_key"
}
```

**Response:**
```json
{
  "plaintext": "decrypted_data"
}
```

### POST /api/stream/rsa-encrypt
Encrypt with RSA-2048 public key

**Request:**
```json
{
  "plaintext": "data to encrypt",
  "publicKeyPem": "-----BEGIN PUBLIC KEY-----\n..."
}
```

**Response:**
```json
{
  "ciphertext": "base64_encrypted_data"
}
```

### GET /api/stream/rate-limit-status?clientId=abc123
Check rate limit status

**Response:**
```json
{
  "clientId": "abc123",
  "remainingTokens": 45,
  "refillRate": "60 per minute",
  "allowed": true
}
```

## Error Responses

**429 Too Many Requests:**
```json
{
  "error": "Rate limit exceeded"
}
```

**400 Bad Request:**
```json
{
  "error": "Invalid encryption parameters"
}
```
