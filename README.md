# Etapa 4 - Seguridad e Integridad

## Objetivos Cumplidos:
✅ Principio de mínimo privilegio  
✅ Vistas para ocultar información sensible  
✅ Validación de restricciones de integridad  
✅ Consultas seguras contra SQL injection  

## Usuarios Creados:
- estudiante_consulta: Solo lectura de vistas públicas
- bibliotecario_gestor: Gestión de datos pero no estructura
- admin_biblioteca: Control total de datos

## Pruebas de Seguridad:
- SQL Injection: ✅ Neutralizado con parámetros preparados
- Integridad: ✅ PK, FK, UNIQUE, CHECK validados
- Privilegios: ✅ Acceso restringido por rol