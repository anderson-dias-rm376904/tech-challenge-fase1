# Model Lab — dashboard web

Dashboard FastAPI que consome os arquivos gerados por
`notebooks/08_export_web.ipynb`.

## Executar

1. Execute o notebook 05 e depois o notebook 08.
2. Na raiz do repositório, execute:

   ```powershell
   .\run_web.ps1
   ```

O script prepara o ambiente virtual, instala as dependências e usa a primeira
porta livre entre `8010`, `8011`, `8012` e `8013`.

Para escolher outra porta:

```powershell
.\run_web.ps1 -Port 8020
```

A URL do dashboard e da documentação da API são exibidas ao iniciar.
