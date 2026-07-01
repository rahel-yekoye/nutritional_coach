# Deployment Guide

This guide covers deploying the Ethiopian Food Database API to various cloud platforms.

## Prerequisites

Before deploying, ensure you have:
- ✅ All required data files: `search_index.json` and `cleaned_inverted_index.json`
- ✅ Node.js 14+ installed (for local testing)
- ✅ Git repository initialized

## Quick Deploy Options

### 🚀 Option 1: Render (Recommended - Free Tier Available)

1. **Create Account**: Go to [render.com](https://render.com) and sign up
2. **Connect Repository**: Link your GitHub/GitLab repository
3. **Create Web Service**:
   - Click "New +" → "Web Service"
   - Select your repository
   - Configure:
     - **Name**: `ethiopian-food-api`
     - **Region**: Choose closest to your users
     - **Branch**: `main`
     - **Build Command**: `npm install`
     - **Start Command**: `npm start`
     - **Plan**: Free (or upgrade for better performance)

4. **Environment Variables**:
   ```
   NODE_ENV=production
   PORT=3000
   RATE_LIMIT_MAX_REQUESTS=100
   CACHE_MAX_SIZE=1000
   ```

5. **Deploy**: Click "Create Web Service"

Your API will be live at: `https://ethiopian-food-api.onrender.com`

**Note**: Free tier spins down after inactivity (takes ~1 minute to wake up).

---

### 🚂 Option 2: Railway

1. **Create Account**: Go to [railway.app](https://railway.app)
2. **New Project**:
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
3. **Configuration**:
   - Railway auto-detects Node.js
   - Add environment variables in the Variables tab:
     ```
     NODE_ENV=production
     RATE_LIMIT_MAX_REQUESTS=100
     ```
4. **Deploy**: Railway deploys automatically

Your API will be live at the generated Railway domain.

**Cost**: Free trial credits, then pay-as-you-go (~$5/month for light usage).

---

### 🟣 Option 3: Heroku

1. **Install Heroku CLI**:
   ```bash
   # Windows (Chocolatey)
   choco install heroku-cli
   
   # macOS
   brew tap heroku/brew && brew install heroku
   ```

2. **Login and Create App**:
   ```bash
   heroku login
   heroku create ethiopian-food-api
   ```

3. **Set Environment Variables**:
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set RATE_LIMIT_MAX_REQUESTS=100
   ```

4. **Deploy**:
   ```bash
   git push heroku main
   ```

5. **Open App**:
   ```bash
   heroku open
   ```

Your API will be live at: `https://ethiopian-food-api.herokuapp.com`

**Cost**: ~$7/month for basic dyno.

---

### 🐳 Option 4: Docker (Any Platform)

**Dockerfile** (already included in project):

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy application code and data files
COPY . .

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["npm", "start"]
```

**Build and Run**:
```bash
# Build image
docker build -t efct-api .

# Run container
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  -e RATE_LIMIT_MAX_REQUESTS=100 \
  efct-api

# Or use docker-compose
docker-compose up -d
```

**Docker Compose** (create `docker-compose.yml`):
```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - RATE_LIMIT_MAX_REQUESTS=100
      - CACHE_MAX_SIZE=1000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Deploy to any Docker-compatible platform (AWS ECS, Google Cloud Run, Azure Container Instances, DigitalOcean App Platform).

---

### ☁️ Option 5: AWS (Elastic Beanstalk)

1. **Install AWS CLI and EB CLI**:
   ```bash
   pip install awsebcli
   ```

2. **Initialize**:
   ```bash
   eb init -p node.js ethiopian-food-api
   ```

3. **Create Environment**:
   ```bash
   eb create production
   ```

4. **Set Environment Variables**:
   ```bash
   eb setenv NODE_ENV=production RATE_LIMIT_MAX_REQUESTS=100
   ```

5. **Deploy Updates**:
   ```bash
   eb deploy
   ```

**Cost**: ~$10-20/month for t2.micro instance.

---

## Post-Deployment Checklist

After deploying, verify your API:

### 1. Health Check
```bash
curl https://your-domain.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "uptime": 123.45,
  "data": {
    "foods_loaded": 374,
    "keywords_indexed": 393
  }
}
```

### 2. Test Search
```bash
curl "https://your-domain.com/search?q=barley&limit=5"
```

### 3. Test Autocomplete
```bash
curl "https://your-domain.com/suggest?q=wh"
```

### 4. Test Food Details
```bash
curl "https://your-domain.com/food/010007"
```

### 5. Monitor Performance
- Check response times (should be <50ms for cached queries)
- Monitor memory usage (should be ~50-100MB)
- Verify cache hit rates in `/health` endpoint

---

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment (production/development) |
| `CACHE_MAX_SIZE` | `1000` | Total cache size |
| `SEARCH_CACHE_SIZE` | `500` | Search results cache size |
| `SUGGEST_CACHE_SIZE` | `500` | Autocomplete cache size |
| `RATE_LIMIT_MAX_REQUESTS` | `100` | Requests per minute per IP |
| `RATE_LIMIT_WINDOW_MS` | `60000` | Rate limit window (ms) |
| `CORS_ORIGIN` | `*` | CORS allowed origins |
| `HELMET_ENABLED` | `true` | Enable security headers |

---

## Performance Tuning

### For High Traffic (>100 req/sec)

1. **Increase Cache Sizes**:
   ```
   CACHE_MAX_SIZE=5000
   SEARCH_CACHE_SIZE=3000
   SUGGEST_CACHE_SIZE=2000
   ```

2. **Add Redis for Distributed Caching** (optional):
   - Install: `npm install redis`
   - Update cache implementation to use Redis

3. **Use Load Balancer**:
   - Deploy multiple instances behind a load balancer
   - Session affinity not required (stateless API)

4. **Enable Compression**:
   Already enabled via Express compression middleware

### For Low Memory Environments

Reduce cache sizes:
```
CACHE_MAX_SIZE=500
SEARCH_CACHE_SIZE=300
SUGGEST_CACHE_SIZE=200
```

---

## Monitoring

### Recommended Monitoring Services

1. **Uptime Monitoring**:
   - UptimeRobot (free)
   - Pingdom
   - StatusCake

2. **Application Monitoring**:
   - New Relic
   - Datadog
   - Application Insights (Azure)

3. **Logging**:
   - Papertrail
   - Loggly
   - CloudWatch (AWS)

### Health Check Endpoint

Point your monitoring to: `https://your-domain.com/health`

---

## Troubleshooting

### Server Won't Start

**Problem**: Port already in use
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution**: Change PORT environment variable or kill existing process.

### High Memory Usage

**Problem**: Memory usage >200MB

**Solution**: Reduce cache sizes or upgrade server plan.

### Slow Responses

**Problem**: Response time >100ms

**Possible Causes**:
1. Cold start (free tier platforms)
2. Cache not warming up
3. Need more resources

**Solutions**:
1. Upgrade to paid tier (no cold starts)
2. Add warmup requests on startup
3. Scale horizontally (multiple instances)

### 429 Rate Limit Errors

**Problem**: Too many requests

**Solution**: Increase `RATE_LIMIT_MAX_REQUESTS` or implement API keys for higher limits.

---

## Security Considerations

1. **CORS**: In production, set specific origins:
   ```
   CORS_ORIGIN=https://your-frontend.com
   ```

2. **Rate Limiting**: Already enabled (100 req/min per IP)

3. **Helmet**: Security headers automatically applied

4. **Input Validation**: All inputs sanitized

5. **HTTPS**: Use platform SSL/TLS (free on most platforms)

---

## Scaling Guidelines

| Traffic Level | Recommended Setup | Estimated Cost |
|---------------|-------------------|----------------|
| <1K req/day | Free tier (Render/Railway) | $0 |
| 1K-10K req/day | Basic paid tier | $5-10/month |
| 10K-100K req/day | Scaled instances + CDN | $20-50/month |
| >100K req/day | Load balanced + Redis cache | $100+/month |

---

## Support

For deployment issues:
- Check server logs first
- Review environment variables
- Test locally with production settings
- Contact platform support if needed

## Next Steps

After successful deployment:
1. Set up monitoring
2. Configure custom domain (optional)
3. Add CI/CD pipeline (optional)
4. Implement API analytics (optional)
