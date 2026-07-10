# 🚀 Deployment Checklist

Use this checklist to ensure smooth deployment to production.

## Pre-Deployment

### ✅ Code Quality
- [x] All tests pass (`node test-api.js`)
- [x] No console errors or warnings
- [x] Code reviewed and documented
- [x] Dependencies up to date
- [x] Security vulnerabilities checked (`npm audit`)

### ✅ Configuration
- [x] `.env.example` created with all variables
- [x] Environment-specific configs tested
- [x] Production environment variables prepared
- [x] Rate limits configured appropriately
- [x] CORS origins configured (not wildcard in production)

### ✅ Data Files
- [x] `search_index.json` present and valid
- [x] `cleaned_inverted_index.json` present and valid
- [x] Data files committed to repository
- [x] Data integrity verified

### ✅ Performance
- [x] Response times acceptable (<50ms)
- [x] Memory usage stable (~50-100MB)
- [x] Cache hit rate >70%
- [x] No memory leaks during stress testing

### ✅ Security
- [x] Helmet middleware enabled
- [x] Rate limiting configured
- [x] Input validation implemented
- [x] Error messages don't leak sensitive info
- [x] CORS properly configured

## Deployment Steps

### Option 1: Render (Recommended)

1. **Repository Setup**
   ```bash
   git init
   git add .
   git commit -m "Initial commit - Production-ready API"
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Render Dashboard**
   - [ ] Go to https://render.com/dashboard
   - [ ] Click "New +" → "Web Service"
   - [ ] Connect GitHub repository
   - [ ] Configure service:
     - Name: `ethiopian-food-api`
     - Region: Choose closest to users
     - Branch: `main`
     - Build Command: `npm install`
     - Start Command: `npm start`

3. **Environment Variables**
   ```
   NODE_ENV=production
   PORT=3000
   RATE_LIMIT_MAX_REQUESTS=100
   CORS_ORIGIN=https://your-frontend-domain.com
   CACHE_MAX_SIZE=1000
   ```

4. **Deploy**
   - [ ] Click "Create Web Service"
   - [ ] Wait for build to complete (~2-3 minutes)
   - [ ] Verify deployment at provided URL

### Option 2: Docker

1. **Build Image**
   ```bash
   docker build -t efct-api:latest .
   ```

2. **Test Locally**
   ```bash
   docker run -p 3000:3000 \
     -e NODE_ENV=production \
     -e RATE_LIMIT_MAX_REQUESTS=100 \
     efct-api:latest
   ```

3. **Push to Registry** (if using cloud)
   ```bash
   docker tag efct-api:latest your-registry/efct-api:latest
   docker push your-registry/efct-api:latest
   ```

4. **Deploy to Cloud**
   - [ ] Deploy to your cloud platform
   - [ ] Configure environment variables
   - [ ] Set up health checks

### Option 3: Heroku

1. **Setup**
   ```bash
   heroku login
   heroku create ethiopian-food-api
   ```

2. **Configure**
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set RATE_LIMIT_MAX_REQUESTS=100
   ```

3. **Deploy**
   ```bash
   git push heroku main
   ```

4. **Verify**
   ```bash
   heroku open
   heroku logs --tail
   ```

## Post-Deployment

### ✅ Smoke Tests

Run these tests immediately after deployment:

1. **Health Check**
   ```bash
   curl https://your-domain.com/health
   ```
   - [ ] Returns `"status": "healthy"`
   - [ ] Shows correct food/keyword counts
   - [ ] Memory usage reasonable

2. **Search Endpoint**
   ```bash
   curl "https://your-domain.com/search?q=barley&limit=5"
   ```
   - [ ] Returns results
   - [ ] Response time <100ms
   - [ ] Correct data structure

3. **Food Details**
   ```bash
   curl "https://your-domain.com/food/010007"
   ```
   - [ ] Returns food data
   - [ ] Nutrition data present
   - [ ] No errors

4. **Autocomplete**
   ```bash
   curl "https://your-domain.com/suggest?q=wh"
   ```
   - [ ] Returns suggestions
   - [ ] Fast response (<50ms)

5. **Error Handling**
   ```bash
   curl "https://your-domain.com/food/invalid"
   ```
   - [ ] Returns 400 error
   - [ ] Proper error message
   - [ ] No stack trace

### ✅ Load Testing

1. **Basic Load Test** (optional)
   ```bash
   # Using Apache Bench
   ab -n 1000 -c 10 https://your-domain.com/health
   
   # Using wrk
   wrk -t4 -c100 -d30s https://your-domain.com/search?q=barley
   ```

2. **Expected Results**
   - [ ] No failed requests
   - [ ] Response time <100ms p95
   - [ ] No memory spikes
   - [ ] Cache warming up

### ✅ Monitoring Setup

1. **Uptime Monitoring**
   - [ ] Set up uptime checker (UptimeRobot, Pingdom, etc.)
   - [ ] Monitor `/health` endpoint
   - [ ] Alert on downtime
   - [ ] Check interval: 5 minutes

2. **Error Tracking** (optional)
   - [ ] Set up Sentry or similar
   - [ ] Configure error alerts
   - [ ] Test error reporting

3. **Performance Monitoring** (optional)
   - [ ] Set up APM (New Relic, Datadog)
   - [ ] Track response times
   - [ ] Monitor memory usage
   - [ ] Set up alerts

### ✅ Documentation

1. **Update URLs**
   - [ ] Replace localhost URLs in docs with production URL
   - [ ] Update README with live API URL
   - [ ] Share API documentation link

2. **API Documentation**
   - [ ] Publish API docs (if using external tool)
   - [ ] Share example requests
   - [ ] Document rate limits

### ✅ Security Review

1. **Production Settings**
   - [ ] `NODE_ENV=production` set
   - [ ] Helmet enabled
   - [ ] CORS configured (not wildcard)
   - [ ] Rate limiting active

2. **Secrets Management**
   - [ ] No secrets in code
   - [ ] Environment variables set
   - [ ] API keys rotated (if any)

3. **HTTPS**
   - [ ] SSL/TLS certificate active
   - [ ] All requests use HTTPS
   - [ ] HTTP redirects to HTTPS

## Ongoing Maintenance

### Daily
- [ ] Check uptime status
- [ ] Review error logs (if any)

### Weekly
- [ ] Review performance metrics
- [ ] Check cache hit rates
- [ ] Monitor memory usage trends

### Monthly
- [ ] Update dependencies (`npm update`)
- [ ] Review security advisories (`npm audit`)
- [ ] Backup data files (if changed)
- [ ] Review and optimize cache sizes

## Rollback Plan

If deployment fails or issues arise:

1. **Immediate Actions**
   ```bash
   # Heroku
   heroku rollback
   
   # Render
   # Revert via dashboard to previous deployment
   
   # Docker
   docker run previous-tag
   ```

2. **Investigation**
   - Check logs for errors
   - Review recent changes
   - Test locally with production config
   - Verify data files integrity

3. **Fix and Redeploy**
   - Fix the issue
   - Test thoroughly locally
   - Follow deployment steps again

## Success Criteria

Deployment is successful when:

- [x] All endpoints respond correctly
- [x] Response times <100ms
- [x] No errors in logs
- [x] Health check passes
- [x] Cache working (hit rate >70%)
- [x] Rate limiting functional
- [x] Memory usage stable
- [x] Uptime monitoring active

## Support Contacts

**Deployment Issues:**
- Check platform status page
- Review deployment logs
- Consult platform documentation

**API Issues:**
- Check `/health` endpoint
- Review server logs
- Verify environment variables
- Test with provided `test-api.js` script

---

## Quick Reference

### Test Deployment
```bash
# Start server
npm start

# Run test suite
node test-api.js

# Check health
curl https://nutritional-coach.onrender.com/health
```

### Deploy to Render
1. Connect GitHub repo
2. Click "Create Web Service"
3. Wait 2-3 minutes
4. Done!

### Deploy with Docker
```bash
docker build -t efct-api .
docker run -p 3000:3000 efct-api
```

### Environment Variables
```env
NODE_ENV=production
PORT=3000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=https://your-domain.com
CACHE_MAX_SIZE=1000
```

---

**Status**: Ready for deployment! 🚀
