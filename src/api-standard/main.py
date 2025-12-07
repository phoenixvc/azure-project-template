from fastapi import FastAPI
app = FastAPI()

@app.get('/')
async def root():
    return {'message': 'API Standard'}

@app.get('/health')
async def health():
    return {'status': 'healthy'}
