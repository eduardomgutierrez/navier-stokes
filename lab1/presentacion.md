---
marp: true
---

# Laboratorio 1 - Optimización secuencial

###### 15 de Abril de 2021

### Proyecto: Navier - Stokes

### Alumnos:
- Eduardo Mario Gutierrez
- Stizza, Federico
  
---

# Hardware


**CPU:** Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz

*Velocidad:* **800MHz - 4500MHz**
*Ancho de banda máximo soportado:* **41.8 GB/s**
*Benchmark ERT*: **83.7 GFLOPs/sec.**

**MEMORIA:**

| Tipo   | Tamaño | Ancho de banda (ERT) |
| ------ | ------ | -------------------- |
| *L1*   | 32kB   | 202.9 GB/s           |
| *L2*   | 256kB  | 166.6 GB/s           |
| *L3*   | 12MB   | 130.2 GB/s           |
| *DRAM* | 16GB   | 27.9 GB/s.           |
 
- *L1* en realidad se divide en *L1I*, *L1D* ambos de **32kB**.

---

# Benchmark



![height:16cm](ert.jpg )

<!-- https://relate.cs.illinois.edu/course/cs598apk-f18/f/demos/upload/perf/Using%20Performance%20Counters.html -->

---

# Software

**Sistema Operativo**
* *OS*: Ubuntu
* *Versión*: 20.04.2 LTS
* *Arquitectura*: x86_64

**Compiladores**
* *gcc* 9.3.0
* *clang* 10.0.0-4

---

# Flags

Con el objetivo de mejorar la performance del programa base se analizó la perfomance del código compilando con *gcc* y *clang* utilizando diferentes flags de compilación.
* -O1
* -O2
* -O3
* -Ofast
* -march=native
* -ffast-math
* -funroll-loop

---


---

<!-- 
Cosas para hacer
================

1.  Encontrar una métrica de performance del problema.
    :   -   Que sea comparable **para cualquier tamaño del problema**.
        -   Mejor performance para mayores valores.
        -   Idealmente FLOPS/IPS si se puede calcular.

2.  Mejorar la performance cambiando cosas, por ejemplo:
    :   -   Compiladores. (GCC, Clang, Intel, NVIDIA/PGI?)
        -   Opciones de compilación. (explorar mucho)
        -   Mejoras algorítmicas y/o numéricas. (si hubiera, e.g. RNG)
        -   Optimizaciones de cálculos. (que no haga ya el compilador)
        -   Unrolling de loops y otras fuentes de ILP. (nuevamente, que
            no haga el compilador)
        -   Sistema de memoria: Hugepages y estrategias cache-aware.
            (altamente probable que no rindan hasta agregar paralelismo,
            ni para sistemas pequeños)

Hints
=====

-   Tomar decisiones sobre dónde mirar primero en el código haciendo
    profiling. (perf, VTune)
-   Automatizar **TODO**, es una inversión para todo el cuatrimestre:
    :   -   Compilación.
        -   Tests para detectar rápido problemas en el código.
        -   Ejecución y medición de performance.
        -   Procesamiento de la salida del programa. (salida en CSV es
            fácil de ingerir)
        -   Generación de gráficas.

Entrega
=======

Presentación de los resultados en clase (10 minutos) e informe breve.

-   Características del hardware y del software:
    :   -   CPU: modelo y velocidad.
            :   -   Poder de cómputo de un core medido con Empirical
                    Roofline Toolkit o LINPACK.

        -   Memoria: capacidad, velocidad, cantidad de canales ocupados.
            :   -   Ancho de banda para un core medido con Empirical
                    Roofline Toolkit o STREAM.

        -   Compiladores: nombres y versiones.
        -   Sistema Operativo: nombre, versión, arquitectura.

-   Gráficas de scaling para la versión más rápida obtenida.
    :   -   Performance vs. tamaño del problema. (usualmente lin-log)
        -   No va a dar scaling lineal, hay que explorar tamaños
            encontrando relaciones con la jerarquía de memoria.
        -   [Considerar la calidad estadística de los
            resultados](https://www.youtube.com/watch?v=r-TLSBdHe1A).

-   Optimizaciones probadas y sus resultados.
    :   -   Explicación y mediciones que validen la explicación.
        -   [Intentar medir las
            causas](https://travisdowns.github.io/blog/2019/06/11/speed-limits.html)
            además de la performance.

-->