# Laboratorio 2 - Vectorización

###### 13 de Mayo de 2021

### Proyecto: Navier - Stokes

### Alumnos:
- Eduardo, Mario Gutierrez
- Stizza, Federico
  
---

# Resultados laboratorio 1

![Lab1](./lab1.jpeg)

---

# Equilibrando el problema

La optimización del primer laboratorio que más performance aportó al problema fue la del cambio de criterio de convergencia de la función **lin_solve**. 

Como se puede ver en el gráfico anterior, para los tamaños de problema grandes, la performance es muy alta, esto se debe a que el problema original posee una sola fuente en el centro  y para tamaños grandes la mayor parte de las celdas no tienen valores para calcular y por el criterio antes mencionado la ejecución termina casi sin iterar.

Por lo tanto, decidimos agregar fuentes en distintas partes de la matriz, no solo en el centro para que la medida sea más real.

#### Con la única fuente
![height:5cm](./viejo.png)

| N    | Cell/ms |
| ---- | ------- |
| 64   | 6.423   |
| 512  | 9.784   |
| 1024 | 29.620  |

#### Con múltiples fuentes proporcional al tamaño de la matriz

![height:5cm](./nuevo.png)

| N    | Cell/ms |
| ---- | ------- |
| 64   | 5.922   |
| 512  | 5.745   |
| 1024 | 8.129   |

Podemos observar que la performance se mantiene estable para los tamaños pequeños y para el tamaño más grande baja, lo que creemos que es relativamente normal teniendo en cuenta que a mayor tamaño se agrega más cantidad de fuentes y por lo tanto tiene más carga que para los otros problemas.

Por lo que consideramos estos valores como la base de comparación.

# Autovectorización

| COMPILADOR - Version | Autovectorizó |
| -------------------- | ------------- |
| GCC-                 |               |
| GCC-                 |               |
| CLANG-               |               |
| CLANG-               |               |
| ICC-                 |               |
| CLANG-               |               |

### Ayudando al compilador

Uno de los mensajes que encontramos en los reportes de autovectorizacion en la compilacion fue: 
- Reemplazamos en todos los loops, la variable del tamaño n, por una constante definida en compile-time. 

# Vectorización explícita (ISPC)



<!-- source /opt/intel/oneapi/setvars.sh intel64 -->

<!-- ../headless.c:184:5: remark: loop not vectorized: cannot prove it is safe to reorder memory operations; allow reordering by specifying '#pragma clang loop vectorize(enable)' before the loop. If the arrays will always be independent specify '#pragma clang loop vectorize(assume_safety)' before the loop or provide the '__restrict__' qualifier with the independent array arguments. Erroneous results will occur if these options are incorrectly applied! [-Rpass-analysis=loop-vectorize] -->

<!-- ../solver.c:49:5: remark: loop not vectorized: could not determine number of loop iterations [-Rpass-analysis=loop-vectorize] -->

<!-- https://postgrespro.com/list/thread-id/2495746 -->