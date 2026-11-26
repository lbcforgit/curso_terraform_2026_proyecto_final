# Tarea 6.1 · Proyecto final

Sube en esta tarea:

1. **`entrega.zip`**, generado con `./scripts/empaquetar.sh`. Incluye todo tu proyecto y `DOCUMENTACION.md` completo.
2. **Las capturas de los pasos 2 a 7:**
   1. [X] El *bucket del estado* (consola de S3 o Floci UI).
   2. [X] El primer análisis de **Trivy**, con los hallazgos HIGH y CRITICAL.
   3. [X] Trivy sin hallazgos HIGH ni CRITICAL, tras corregir o justificar.
   4. [ ] El *CI en verde*: la pestaña Actions de GitHub, o `./scripts/ci.sh` terminando sin errores.
   5. [ ] El **registro del despliegue** de prueba, con las instancias creadas y la destrucción final.
   6. [ ] Las **instancias** de `dev` y `pro` desplegadas (consola de EC2 o Floci UI).
   7. [ ] Solo con AWS: una página de producción en el navegador.

## Requisitos obligatorios

- Los módulos `red`, `servidor_web` y `logs`, reutilizados por los dos entornos.
- Dos entornos, `dev` y `pro`, cada uno en su directorio y con su estado en S3 con bloqueo.
- Ningún hallazgo HIGH o CRITICAL de Trivy sin justificar. Cada excepción debe ir comentada en el código y en `DOCUMENTACION.md`.
- El CI y el despliegue de prueba funcionando, en GitHub Actions o con los scripts en local.
