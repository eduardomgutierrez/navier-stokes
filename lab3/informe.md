# Laboratorio 2 - Vectorización

###### 13 de Mayo de 2021

### Proyecto: Navier - Stokes

### Alumnos:
- Eduardo, Mario Gutierrez
- Stizza, Federico
  
---

# Resultados laboratorio 2

![Resultados laboratorio 2](./resultados.jpeg)

# Independencia de cálculo

En el laboratorio anterior reestructuramos la información de las celdas utilizando el ordenamiento *Red-Black*.

Nuevamente la función a optimizar sigue siendo *lin_solve* y por lo mencionado anteriormente el cálculo de las casillas rojas es independiente de las casillas negras.

# Paralelizando

En primer lugar, modificamos el código vectorial del laboratorio anterior para así llamarlo desde el *lin_solve*.

El *lin_solve* vectorial ahora es paramétrizado por unos 

Utilizando la libreria *OpenMP* agregamos a la función directivas de paralelismo al principio y final de la misma con la cláusula:



```c
#pragma omp parallel
```

Luego para paralelizar los loops usamos:

```c
#pragma omp for reduction(+:cont1, acum1)
```

advixe-cl --collect=roofline ./headless


