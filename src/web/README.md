# Model Lab — dashboard web

Dashboard FastAPI com duas visões independentes:

| Rota | Estudo | Export necessário |
|------|--------|-------------------|
| `/` | Câncer de mama | `notebooks/breast-cancer-wisconsin-data/08_export_web.ipynb` |
| `/pcos` | SOP (PCOS) | `notebooks/polycystic-ovary-syndrome-pcos/05_export_web.ipynb` |

Use o menu **Estudo** na sidebar para alternar entre as páginas.

## Executar

1. Execute os notebooks de export de cada estudo que deseja visualizar.
2. Na raiz do repositório:

   ```powershell
   .\run_web.ps1
   ```

O script prepara o ambiente virtual, instala dependências e usa a primeira porta livre entre `8010`–`8013`.

```powershell
.\run_web.ps1 -Port 8020
```

## API

- Mama: `/api/metricas`, `/api/graficos`, `/api/amostras`
- PCOS: `/api/pcos/metricas`, `/api/pcos/graficos`, `/api/pcos/amostras`
