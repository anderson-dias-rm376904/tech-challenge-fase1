from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from src.web.api.routes import router


WEB_DIR = Path(__file__).resolve().parent

app = FastAPI(
    title="Breast Cancer Model Lab",
    description="Dashboard comparativo dos modelos de classificação.",
    version="1.0.0",
)
app.include_router(router)
app.mount("/static", StaticFiles(directory=WEB_DIR / "static"), name="static")

templates = Jinja2Templates(directory=WEB_DIR / "templates")


@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={},
    )
