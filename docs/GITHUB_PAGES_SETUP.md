# Configuración de GitHub Pages para OptiPlant.jl

## Para configurar la documentación en GitHub Pages:

### 1. Habilitar GitHub Pages en el repositorio

1. Ve a tu repositorio en GitHub: `https://github.com/njbca/OptiPlant`
2. Ve a **Settings** > **Pages**
3. En **Source**, selecciona **GitHub Actions**
4. La documentación se desplegará automáticamente cuando hagas push a las ramas `main` o `Development`

### 2. URLs de la documentación

Una vez configurado GitHub Pages, la documentación estará disponible en:

- **Stable**: `https://njbca.github.io/OptiPlant/stable/`
- **Latest**: `https://njbca.github.io/OptiPlant/latest/`
- **Root**: `https://njbca.github.io/OptiPlant/` (redirige a stable)

### 3. Workflow automático

El archivo `.github/workflows/docs.yml` está configurado para:
- Construir la documentación automáticamente en push/PR
- Desplegar a GitHub Pages cuando se actualiza `main` o `Development`
- Crear versiones `stable` y `latest` de la documentación

### 4. Estructura final

```
OptiPlant/
├── .github/workflows/docs.yml    # Workflow para despliegue automático
├── docs/
│   ├── make.jl                   # Script de construcción
│   ├── Project.toml              # Dependencias de documentación
│   └── src/
│       ├── index.md              # Página principal
│       ├── installation.md       # Guía de instalación
│       ├── usage.md              # Guía de uso
│       ├── Examples.md           # Ejemplos prácticos
│       └── api.md               # Referencia API
└── README.md                     # Enlaces a documentación
```

### 5. Para actualizar la documentación

1. Edita los archivos en `docs/src/`
2. Haz commit y push a `Development` o `main`
3. GitHub Actions construirá y desplegará automáticamente
4. La documentación estará disponible en unos minutos

### 6. Verificación local

Para probar localmente antes de hacer push:

```bash
cd OptiPlant
julia --project=docs docs/make.jl
cd docs/build
python -m http.server 8000
# Abre http://localhost:8000 en tu navegador
```