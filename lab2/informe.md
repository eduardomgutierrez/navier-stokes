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

Probamos de autovectorizar nuestro código con diferentes versiones de **clang** y **gcc**.

Aunque si autovectorizó algunos *loops*, no hizo ningún efecto en el loop principal de *lin_solve*, que es la función que más carga tiene en el programa.

Guíandonos por los mensajes de reporte generado por los compiladores realizamos ciertos cambios para ayudar al compilador para que autovectorice:

- Le agregamos el modificador **restrict** a los punteros de la matriz, para evitar el aliasing de memoria.
- Reemplazamos las cotas de los *loops* por constantes.
- Cambiamos las condiciones de terminación de los *loops* en vez de ```<= n ``` a ``` < n + 1 ``` (sugerencia encontrada en un foro).
- Agregamos instrucciones de preprocesador como 

| COMPILADOR - Version | Autovectorizó |
| -------------------- | ------------- |
| GCC-9                 |               |
| GCC-                 |               |
| CLANG-               |               |
| CLANG-               |               |
| ICC-                 |               |
| CLANG-               |               |



# Vectorización explícita (ISPC)


<!-- source /opt/intel/oneapi/setvars.sh intel64 -->

<!-- ../headless.c:184:5: remark: loop not vectorized: cannot prove it is safe to reorder memory operations; allow reordering by specifying '#pragma clang loop vectorize(enable)' before the loop. If the arrays will always be independent specify '#pragma clang loop vectorize(assume_safety)' before the loop or provide the '__restrict__' qualifier with the independent array arguments. Erroneous results will occur if these options are incorrectly applied! [-Rpass-analysis=loop-vectorize] -->

<!-- ../solver.c:49:5: remark: loop not vectorized: could not determine number of loop iterations [-Rpass-analysis=loop-vectorize] -->

<!-- https://postgrespro.com/list/thread-id/2495746 -->