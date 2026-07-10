# Ethiopian Food Composition Table API

Production-ready REST API for searching and retrieving nutritional data from the Ethiopian Food Composition Table (EFCT).

## Features

✨ **Fast Search Engine** - Intelligent multi-factor ranking with keyword indexing  
🚀 **Production-Ready** - Includes security, rate limiting, CORS, and error handling  
📦 **LRU Caching** - Separate optimized caches for search and suggest endpoints  
⚡ **High Performance** - O(1) inverted index lookups, precomputed data structures  
🔒 **Security** - Helmet middleware, input sanitization, rate limiting  
📊 **Observability** - Request logging, performance metrics, health checks  
🌍 **Deployment-Ready** - Works on Render, Railway, Heroku, or any Node.js host  

## Quick Start

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start the server
npm start
```

The API will start on `https://nutritional-coach.onrender.com`

### Development Mode

```bash
npm run dev
```

### Production Mode

```bash
npm run prod
```

## API Endpoints

### 🔍 Search Foods
```
GET /search?q={query}&limit={limit}
```

Search for foods by name, keywords, or category with intelligent ranking.

**Parameters:**
- `q` (required): Search query string
- `limit` (optional): Maximum results to return (default: 20, max: 100)

**Example:**
```bash
curl "https://nutritional-coach.onrender.com/search?q=barley&limit=10"
```

**Response:**
```json
{
  "query": "barley",
  "result_count": 8,
  "limit": 10,
  "results": [
    {
      "food_code": "010007",
      "food_name": "Barley, whole grain",
      "food_name_amharic": "ገብስ",
      "category": "Cereals and cereal products",
      "score": 25.0,
      "scoreBreakdown": {
        "nameMatch": 5.0,
        "keywordMatch": 0.0,
        "categoryMatch": 0.0
      },
      "matchType": "exact_name",
      "keywords": ["barley", "whole", "grain", "cereal"],
      "nutrition": {
        "energy_kcal": 354,
        "protein_g": 12.5,
        "fat_g": 2.3,
        "carbs_g": 73.5,
        "fiber_g": 17.3
      }
    }
  ],
  "timestamp": "2026-06-07T10:30:00.000Z"
}
```

### 🍽️ Get Food Details
```
GET /food/{food_code}
```

Get complete nutritional information for a specific food.

**Example:**
```bash
curl "https://nutritional-coach.onrender.com/food/010007"
```

### 💡 Autocomplete Suggestions
```
GET /suggest?q={query}
```

Get autocomplete suggestions for food names and keywords.

**Example:**
```bash
curl "https://nutritional-coach.onrender.com/suggest?q=wh"
```

**Response:**
```json
{
  "query": "wh",
  "suggestions": [
    {
      "text": "Wheat, whole grain",
      "type": "food_name"
    },
    {
      "text": "wheat",
      "type": "keyword"
    }
  ],
  "suggestion_count": 2,
  "timestamp": "2026-06-07T10:30:00.000Z"
}
```

### 🏥 Health Check
```
GET /health
```

Check API status, cache statistics, and memory usage.

**Example:**
```bash
curl "https://nutritional-coach.onrender.com/health"
```

## Configuration

Configuration is managed through environment variables. See `.env.example` for all options.

### Key Configuration Options

```env
# Server
PORT=3000
NODE_ENV=production

# Cache Sizes
CACHE_MAX_SIZE=1000
SEARCH_CACHE_SIZE=500
SUGGEST_CACHE_SIZE=500

# Rate Limiting (100 requests per minute per IP)
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_WINDOW_MS=60000

# CORS
CORS_ORIGIN=*
```

## Performance

### Optimizations Implemented

1. **Zero File Reads During Requests** - All data loaded once at startup
2. **O(1) Inverted Index Lookups** - Uses Set instead of arrays
3. **LRU Caching** - Separate caches with automatic eviction
4. **Precomputed Lookup Maps** - Food code, category, and keyword maps
5. **Optimized Search** - Direct lookups before fuzzy matching

### Performance Metrics

- Typical search response time: **5-20ms**
- Cache hit rate: **70-90%** on repeated queries
- Memory footprint: **~50-100MB** including data
- Startup time: **~500ms**

## Deployment

### Render

1. Create a new Web Service on [Render](https://render.com)
2. Connect your repository
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Add environment variables from `.env.example`
6. Deploy!

### Railway

1. Create a new project on [Railway](https://railway.app)
2. Connect your repository
3. Railway will auto-detect Node.js and use `npm start`
4. Add environment variables
5. Deploy!

### Heroku

```bash
# Login to Heroku
heroku login

# Create app
heroku create your-app-name

# Push to Heroku
git push heroku main

# Set environment variables
heroku config:set NODE_ENV=production
```

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t efct-api .
docker run -p 3000:3000 efct-api
```

## Project Structure

```
efct-extractor/
├── server.js                    # Main Express application
├── config.js                    # Centralized configuration
├── search_ranker.js            # Search ranking algorithm
├── middleware/
│   ├── logger.js               # Request timing & logging
│   ├── errorHandler.js         # Global error handling
│   └── rateLimit.js            # Rate limiting
├── routes/
│   ├── search.js               # Search endpoint
│   ├── food.js                 # Food details endpoint
│   └── suggest.js              # Autocomplete endpoint
├── utils/
│   ├── cache.js                # LRU cache implementation
│   └── dataLoader.js           # Data loading utilities
├── search_index.json           # Preprocessed search data
├── cleaned_inverted_index.json # Keyword-to-food mappings
└── package.json
```

## Architecture

### Data Flow

1. **Startup**: Load and preprocess all data files once
2. **Request**: Check cache → Perform search → Cache result
3. **Response**: Return formatted JSON with rankings

### Caching Strategy

- **Search Cache**: Stores complete search results (500 entries)
- **Suggest Cache**: Stores autocomplete suggestions (500 entries)
- **LRU Eviction**: Automatically removes least recently used entries

### Search Ranking

Multi-factor scoring system:
- **Name Match** (0-25 points): Exact, prefix, or substring matches
- **Keyword Match** (0-4 points): Keyword overlap ratio
- **Category Match** (0-1 point): Category relevance

## Monitoring

### Request Logs

Every request is logged with timing:
```
2026-06-07T10:30:00.000Z | GET  /search?q=barley           | 200 | 12ms
```

### Performance Metrics

Access `/health` endpoint for:
- Cache hit rates
- Memory usage
- Foods loaded
- Keywords indexed

### Cache Statistics

In production, cache stats are logged every 5 minutes.

## Security

- **Helmet**: Security headers for XSS, clickjacking protection
- **Rate Limiting**: 100 requests/minute per IP
- **Input Sanitization**: Query length limits, dangerous char removal
- **CORS**: Configurable cross-origin resource sharing
- **Error Handling**: No stack traces in production

## API Response Codes

- `200 OK` - Successful request
- `400 Bad Request` - Invalid parameters
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## License

ISC

## Support

For issues or questions, please open an issue on the repository.
