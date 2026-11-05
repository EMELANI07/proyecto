# Manual de Uso – Subasta de Ganado en Erlang

**Estudiante:** Estrada Rodríguez Melani  
**Materia:** Lenguajes y Autómatas II  
**Tecnología:** Erlang/OTP

---

## 1. Propósito

Sistema de subasta concurrente desarrollado en Erlang, donde cada lote se representa como un proceso independiente.  
El módulo principal (`p65_bitacora`) registra de forma ordenada todos los eventos de la subasta (apertura, pujas, pujas rechazadas y adjudicación).

---

## 2. Requisitos

| Componente       | Detalle                          |
|------------------|----------------------------------|
| Sistema operativo| Ubuntu 22.04 / 24.04 (AWS)       |
| Erlang/OTP       | 25 o superior                    |
| Herramientas     | `erlc`, `erl` (o `rebar3`)       |
| Acceso           | SSH a la instancia AWS           |

---

## 3. Instalación

```bash
# Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd 65-subasta

# Compilar el módulo de bitácora
erlc p65_bitacora.erl
```
> Si el proyecto usa rebar3: ```erl rebar3 compile```

## 4. Ejecución
```erl
# Entrar a la shell de Erlang
erl

%% Una vez dentro de la shell, iniciar el gen_server de la bitácora
p65_bitacora:start_link().

```

## 5. Uso paso a paso 
  
1. Ver lotes / Abrir lotes  
  
```erl
  p65_bitacora:registrar(lote1, abre, "sistema", 0, web).
```
  
2. Pujar (pujas válidas)
  
```erl
  p65_bitacora:registrar(lote1, puja, "juan", 1500, web).
  p65_bitacora:registrar(lote1, puja, "maria", 1800, movil).
  p65_bitacora:registrar(lote1, puja, "carlos", 2000, web).
```
  
3. Puja rechazada (monto menor a la actual)
  
```erl
  p65_bitacora:registrar(lote1, puja_rechazada, "pedro", 1200, web).
  p65_bitacora:registrar(lote1, puja_rechazada, "ana", 1750, movil).
```
  
4. Cierre y ganador
  
```erl
  p65_bitacora:registrar(lote1, adjudicado, "carlos", 2000, web).
```

5. Consultas 
  
```erl
  %% Ver solo los eventos del lote1
  p65_bitacora:eventos(lote1).

  %% Ver toda la bitácora
  p65_bitacora:todos().

  %% Ejemplo de salida:
  [{1,lote1,abre,"sistema",0,web,1793863976587},
 {2,lote1,puja,"juan",1500,web,1793863976588},
 {3,lote1,puja,"maria",1800,movil,1793863976588},
 {4,lote1,puja,"carlos",2000,web,1793863976589},
 {5,lote1,puja_rechazada,"pedro",1200,web,1793863976590},
 {6,lote1,puja_rechazada,"ana",1750,movil,1793863976591},
 {7,lote1,adjudicado,"carlos",2000,web,1793863978395}]
```
  
## 6. Arquitectura
Diagrama: 

UI (navegador) -> Cowboy (HTTP) -> Supervisor OTP -> Procesos de lote + Bitácora (gen_server + ETS)

> Cada lote se maneja de forma concurrente.
La bitácora (p65_bitacora) guarda todos los eventos de forma ordenada usando una tabla ETS ordered_set.

## 7. Solución de problemas

| Problema                        | Solución                                      |
|--------------------------------|-----------------------------------------------|
| `undefined function`           | Compilar primero con `erlc p65_bitacora.erl` |
| Puerto 8080 inaccesible        | Abrir el puerto en el Security Group de AWS  |
| `rebar3: command not found`    | Instalar rebar3 o usar `erl` + `erlc`        |
| Módulo no encontrado           | Verificar que el archivo `.beam` esté en el directorio actual |

## 8. Evidencias
- Grabación Asciinema: [https://asciinema.org/a/1271202](https://asciinema.org/a/1271202) 
- GitHub: [https://github.com/EMELANI07/proyecto/tree/main](https://github.com/EMELANI07/proyecto/tree/main)
