# Quick Start Guide

Get your Ethiopian Food Database API running in 5 minutes!

## 🚀 Local Development

### 1. Install Dependencies
```bash
npm install
```

### 2. Start the Server
```bash
npm start
```

That's it! Your API is now running at `http://localhost:3000`

## 🧪 Test It

### Health Check
```bash
curl http://localhost:3000/health
```

### Search for Food
```bash
curl "http://localhost:3000/search?q=barley"
```

### Get Food Details
```bash
curl "http://localhost:3000/food/010007"
```

### Autocomplete
```bash
curl "http://localhost:3000/suggest?q=wh"
```

## 📱 Use in Your App

### JavaScript
```javascript
const response = await fetch('http://localhost:3000/search?q=barley');
const data = await response.json();
console.log(data.results);
```

### Python
```python
import requests
response = requests.get('http://localhost:3000/search?q=barley')
data = response.json()
print(data['results'])
```

## 🌍 Deploy to Production

### Option 1: Render (Easiest - Free)
1. Go to [render.com](https://render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repo
4. Click "Create Web Service"

Done! Your API will be live in 2 minutes.

### Option 2: Docker
```bash
docker build -t efct-api .
docker run -p 3000:3000 efct-api
```

### Option 3: Heroku
```bash
heroku create
git push heroku main
```

## 📚 More Information

- **Full Documentation**: See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Deployment Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Configuration**: See [README.md](./README.md)

## ⚙️ Configuration (Optional)

Create a `.env` file:
```env
PORT=3000
NODE_ENV=development
RATE_LIMIT_MAX_REQUESTS=100
```

See `.env.example` for all options.

## 🎯 Key Features

✅ Search 374 Ethiopian foods  
✅ Intelligent ranking algorithm  
✅ Autocomplete suggestions  
✅ Complete nutritional data  
✅ 3-20ms response times  
✅ 80% cache hit rate  
✅ Production-ready security  

## 🆘 Troubleshooting

**Port in use?**
```bash
# Change the port
PORT=3001 npm start
```

**Need help?**
- Check `/health` endpoint
- Review server logs
- See [DEPLOYMENT.md](./DEPLOYMENT.md) troubleshooting section

---

**That's it! You're ready to go! 🎉**
