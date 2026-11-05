# Uso paso a paso 

### 1. Arrancar programa.
<img width="624" height="219" alt="image" src="https://github.com/user-attachments/assets/6a5ff461-bab1-4b37-a86a-221652aadff2" />

### 2. Ver lotes / Abrir lotes  
  
```erl
  p65_bitacora:registrar(lote1, abre, "sistema", 0, web).
```
<img width="415" height="49" alt="image" src="https://github.com/user-attachments/assets/09733b11-59f3-49f9-90e6-e5cce5eb6892" />

  
### 3. Pujar (pujas válidas)
  
```erl
  p65_bitacora:registrar(lote1, puja, "juan", 1500, web).
  p65_bitacora:registrar(lote1, puja, "maria", 1800, movil).
  p65_bitacora:registrar(lote1, puja, "carlos", 2000, web).
```
<img width="448" height="157" alt="image" src="https://github.com/user-attachments/assets/fa0ae53d-d968-4e6a-8ca3-711996131e41" />
  
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
```

<img width="381" height="214" alt="image" src="https://github.com/user-attachments/assets/0bfbb2c1-fb63-4771-9ee7-7fd524752566" />
  
