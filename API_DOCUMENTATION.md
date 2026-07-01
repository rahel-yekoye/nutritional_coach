# Ethiopian Food Database API - Documentation

## Base URL
```
Production: https://your-domain.com
Development: http://localhost:3000
```

## Authentication
Currently, no authentication is required. Rate limiting applies to all requests.

## Rate Limiting
- **Limit**: 100 requests per minute per IP address
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Requests remaining in current window
  - `X-RateLimit-Reset`: Timestamp when limit resets
  - `Retry-After`: Seconds to wait if rate limited (429 response)

## Response Format
All responses are in JSON format with consistent structure:

**Success Response**:
```json
{
  "query": "search term",
  "result_count": 10,
  "results": [...],
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

**Error Response**:
```json
{
  "error": "Error Type",
  "message": "Detailed error message",
  "path": "/endpoint",
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

---

## Endpoints

### 1. Search Foods

Search for foods by name, keywords, or category with intelligent ranking.

**Endpoint**: `GET /search`

**Parameters**:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `q` | string | Yes | - | Search query (max 200 chars) |
| `limit` | integer | No | 20 | Results limit (max 100) |

**Example Request**:
```bash
curl "https://your-domain.com/search?q=barley&limit=10"
```

**Example Response**:
```json
{
  "query": "barley",
  "result_count": 3,
  "limit": 10,
  "results": [
    {
      "food_code": "010007",
      "food_name": "Barley",
      "food_name_amharic": "Yetefetege gebs, ti're",
      "category": "Cereals & Grains",
      "score": 29.0,
      "scoreBreakdown": {
        "nameMatch": 5.0,
        "keywordMatch": 2.0,
        "categoryMatch": 0.0
      },
      "matchType": "exact_name",
      "keywords": ["barley", "cereals & grains"],
      "nutrition": {
        "energy_kcal": 329,
        "protein_g": 8.9,
        "fat_g": 2.1,
        "carbs_g": 61.9,
        "fiber_g": 13.7
      }
    }
  ],
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

**Score Breakdown**:
- `nameMatch` (0-5): Name matching quality
  - 5.0 = Exact match
  - 4.0 = Starts with query
  - 3.0 = Contains query
  - 2.0 = Partial word match
- `keywordMatch` (0-2): Keyword overlap ratio
- `categoryMatch` (0-1): Category relevance

**Match Types**:
- `exact_name`: Exact or prefix name match
- `name_match`: Name contains query
- `keyword_match`: Found via keywords
- `category_match`: Found via category

**Error Responses**:
- `400 Bad Request`: Missing or invalid query parameter
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

---

### 2. Get Food Details

Get complete nutritional information for a specific food by its code.

**Endpoint**: `GET /food/:food_code`

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_code` | string | Yes | 6-digit food code (e.g., "010007") |

**Example Request**:
```bash
curl "https://your-domain.com/food/010007"
```

**Example Response**:
```json
{
  "food_code": "010007",
  "food_name": "Barley",
  "food_name_original": "Barley, pearled, dry, raw Yetefetege gebs, ti're",
  "food_name_amharic": "Yetefetege gebs, ti're",
  "normalized_amharic": "yetefetege gebs, ti're",
  "category": "Cereals & Grains",
  "keywords": ["barley", "cereals & grains"],
  "nutrition": {
    "energy_kcal": 329,
    "protein_g": 8.9,
    "fat_g": 2.1,
    "carbs_g": 61.9,
    "fiber_g": 13.7,
    "water_g": 12.0,
    "ash_g": 1.3
  },
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid food code format
- `404 Not Found`: Food code not found
- `500 Internal Server Error`: Server error

---

### 3. Search Foods by Name

Find foods by partial name match.

**Endpoint**: `GET /food/by-name/:name`

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Partial food name (min 2 chars) |

**Example Request**:
```bash
curl "https://your-domain.com/food/by-name/barley"
```

**Example Response**:
```json
{
  "query": "barley",
  "result_count": 3,
  "results": [
    {
      "food_code": "010007",
      "food_name": "Barley",
      "food_name_amharic": "Yetefetege gebs, ti're",
      "category": "Cereals & Grains"
    }
  ],
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

---

### 4. Autocomplete Suggestions

Get autocomplete suggestions for food names and keywords.

**Endpoint**: `GET /suggest`

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Query prefix (max 50 chars) |

**Example Request**:
```bash
curl "https://your-domain.com/suggest?q=wh"
```

**Example Response**:
```json
{
  "query": "wh",
  "suggestions": [
    {
      "text": "Wheat",
      "type": "keyword"
    },
    {
      "text": "wheat",
      "type": "keyword"
    },
    {
      "text": "whisky",
      "type": "keyword"
    },
    {
      "text": "Emmer wheat",
      "type": "food_name"
    }
  ],
  "suggestion_count": 4,
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

**Suggestion Types**:
- `food_name`: Actual food name
- `keyword`: Search keyword

---

### 5. Keyword Suggestions

Get keyword suggestions with food counts.

**Endpoint**: `GET /suggest/keywords`

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Keyword prefix |

**Example Request**:
```bash
curl "https://your-domain.com/suggest/keywords?q=ce"
```

**Example Response**:
```json
{
  "query": "ce",
  "keywords": [
    {
      "keyword": "cereals & grains",
      "food_count": 72
    },
    {
      "keyword": "cereal",
      "food_count": 8
    }
  ],
  "keyword_count": 2,
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

---

### 6. List Categories

Get all available food categories with food counts.

**Endpoint**: `GET /suggest/categories`

**Example Request**:
```bash
curl "https://your-domain.com/suggest/categories"
```

**Example Response**:
```json
{
  "categories": [
    {
      "name": "Cereals & Grains",
      "food_count": 72
    },
    {
      "name": "Meat & Poultry",
      "food_count": 70
    },
    {
      "name": "Vegetables",
      "food_count": 48
    }
  ],
  "total_categories": 17,
  "timestamp": "2026-06-07T10:00:00.000Z"
}
```

---

### 7. Health Check

Check API health status, cache statistics, and memory usage.

**Endpoint**: `GET /health`

**Example Request**:
```bash
curl "https://your-domain.com/health"
```

**Example Response**:
```json
{
  "status": "healthy",
  "uptime": 3600.5,
  "timestamp": "2026-06-07T10:00:00.000Z",
  "environment": "production",
  "data": {
    "foods_loaded": 374,
    "keywords_indexed": 393,
    "categories": 17
  },
  "cache": {
    "search": {
      "name": "search",
      "size": 250,
      "maxSize": 500,
      "hits": 1200,
      "misses": 300,
      "evictions": 50,
      "sets": 300,
      "hitRate": "80.00%",
      "utilizationRate": "50.00%"
    },
    "suggest": {
      "name": "suggest",
      "size": 150,
      "maxSize": 500,
      "hits": 800,
      "misses": 200,
      "evictions": 20,
      "sets": 200,
      "hitRate": "80.00%",
      "utilizationRate": "30.00%"
    }
  },
  "memory": {
    "heapUsed": "45.23 MB",
    "heapTotal": "60.00 MB",
    "rss": "95.50 MB"
  }
}
```

---

### 8. API Root

Get API documentation and available endpoints.

**Endpoint**: `GET /`

**Example Request**:
```bash
curl "https://your-domain.com/"
```

**Example Response**:
```json
{
  "name": "Ethiopian Food Composition Table API",
  "version": "1.0.0",
  "description": "Production-ready REST API for Ethiopian food composition data",
  "endpoints": {
    "search": {
      "url": "GET /search?q={query}&limit={limit}",
      "description": "Search foods by name, keywords, or category",
      "example": "/search?q=barley&limit=10"
    },
    "food": {
      "url": "GET /food/{food_code}",
      "description": "Get complete nutritional data for a specific food",
      "example": "/food/010007"
    },
    "suggest": {
      "url": "GET /suggest?q={query}",
      "description": "Get autocomplete suggestions",
      "example": "/suggest?q=wh"
    },
    "health": {
      "url": "GET /health",
      "description": "Check API health status"
    }
  },
  "statistics": {
    "totalFoods": 374,
    "totalKeywords": 393,
    "avgKeywordsPerFood": 3.72
  }
}
```

---

## Caching

The API implements LRU (Least Recently Used) caching:

- **Search Cache**: Stores search results (500 entries)
- **Suggest Cache**: Stores autocomplete suggestions (500 entries)
- **Cache Headers**: Responses include `cached: true` when served from cache

**Cache Benefits**:
- Typical search: ~15ms (uncached) → ~3ms (cached)
- 70-90% cache hit rate on repeated queries

---

## HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid parameters |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

---

## Best Practices

### 1. Use Caching
Repeated queries are cached automatically. No special handling needed.

### 2. Handle Rate Limits
Check `X-RateLimit-Remaining` header and implement backoff:

```javascript
if (response.headers['x-ratelimit-remaining'] < 10) {
  // Slow down requests
  await sleep(1000);
}
```

### 3. Validate Food Codes
Food codes must be 6 digits: `010007`

### 4. Use Autocomplete
For search UIs, use `/suggest` for instant feedback.

### 5. Error Handling
Always handle error responses:

```javascript
try {
  const response = await fetch('/search?q=barley');
  if (!response.ok) {
    const error = await response.json();
    console.error(error.message);
  }
  const data = await response.json();
} catch (error) {
  console.error('Network error:', error);
}
```

---

## Example Integration

### JavaScript/TypeScript

```javascript
class EthiopianFoodAPI {
  constructor(baseUrl = 'https://your-domain.com') {
    this.baseUrl = baseUrl;
  }

  async search(query, limit = 20) {
    const response = await fetch(
      `${this.baseUrl}/search?q=${encodeURIComponent(query)}&limit=${limit}`
    );
    if (!response.ok) throw new Error('Search failed');
    return await response.json();
  }

  async getFood(foodCode) {
    const response = await fetch(`${this.baseUrl}/food/${foodCode}`);
    if (!response.ok) throw new Error('Food not found');
    return await response.json();
  }

  async suggest(query) {
    const response = await fetch(
      `${this.baseUrl}/suggest?q=${encodeURIComponent(query)}`
    );
    if (!response.ok) throw new Error('Suggest failed');
    return await response.json();
  }
}

// Usage
const api = new EthiopianFoodAPI();
const results = await api.search('barley', 10);
console.log(results.results);
```

### Python

```python
import requests

class EthiopianFoodAPI:
    def __init__(self, base_url='https://your-domain.com'):
        self.base_url = base_url
    
    def search(self, query, limit=20):
        response = requests.get(
            f'{self.base_url}/search',
            params={'q': query, 'limit': limit}
        )
        response.raise_for_status()
        return response.json()
    
    def get_food(self, food_code):
        response = requests.get(f'{self.base_url}/food/{food_code}')
        response.raise_for_status()
        return response.json()
    
    def suggest(self, query):
        response = requests.get(
            f'{self.base_url}/suggest',
            params={'q': query}
        )
        response.raise_for_status()
        return response.json()

# Usage
api = EthiopianFoodAPI()
results = api.search('barley', limit=10)
print(results['results'])
```

---

## Support

For API issues or questions:
- Check `/health` endpoint for service status
- Review error messages in response
- Check rate limit headers
- Consult this documentation

## Changelog

### v1.0.0 (2026-06-07)
- Initial production release
- Multi-factor search ranking
- LRU caching system
- Rate limiting
- Security hardening
- Production deployment ready
