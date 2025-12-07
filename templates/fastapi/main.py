from fastapi import FastAPI

app = FastAPI(title="{{PROJECT}}")

@app.get("/")
async def root():
    return {
        "message": "{{PROJECT}}",
        "org": "{{ORG}}",
        "env": "{{ENV}}"
    }

@app.get("/health")
async def health():
    return {"status": "healthy"}
