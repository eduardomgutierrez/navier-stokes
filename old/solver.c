#include "solver.h"
#include "lin_solve.h"
#include <assert.h>
#include <stddef.h>
#include <stdio.h>

#define ABS(x) x < 0.0f ? -x : x

#ifndef N
#define N 1024
#endif

#ifdef RB
static size_t rb_idx(size_t x, size_t y, size_t dim)
{
    assert(dim % 2 == 0);
    size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    size_t offset = (y / 2) + x * (dim / 2);
    return base + offset;
}

#define IX(x, y) (rb_idx((x), (y), (N + 2)))
#else
#define IX(i, j) ((i) + (N + 2) * (j))
#endif

// Simplificar
#define SWAP(x0, x)      \
    {                    \
        float* tmp = x0; \
        x0 = x;          \
        x = tmp;         \
    }

typedef enum boundary {
    NONE = 0,
    VERTICAL = 1,
    HORIZONTAL = 2 
} boundary;

static void add_source(unsigned int n, float* x, const float* s, float dt)
{
    unsigned int size = (n + 2) * (n + 2);
    for (unsigned int i = 0; i < size; i++) {
        x[i] += dt * s[i];
    }
}

static void set_bnd(unsigned int n, boundary b, float* x)
{
    for (unsigned int i = 1; i < n + 1; i++) {
        x[IX(0, i)] = b == VERTICAL ? -x[IX(1, i)] : x[IX(1, i)];
        x[IX(n + 1, i)] = b == VERTICAL ? -x[IX(n, i)] : x[IX(n, i)];
        x[IX(i, 0)] = b == HORIZONTAL ? -x[IX(i, 1)] : x[IX(i, 1)];
        x[IX(i, n + 1)] = b == HORIZONTAL ? -x[IX(i, n)] : x[IX(i, n)];
    }
    x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
    x[IX(0, n + 1)] = 0.5f * (x[IX(1, n + 1)] + x[IX(0, n)]);
    x[IX(n + 1, 0)] = 0.5f * (x[IX(n, 0)] + x[IX(n + 1, 1)]);
    x[IX(n + 1, n + 1)] = 0.5f * (x[IX(n, n + 1)] + x[IX(n + 1, n)]);
}

static void lin_solve(unsigned int n, boundary b, float* restrict x, const float* restrict x0, float a, float c)
{
#ifdef INV_M
    float inv_c = 1.0f / c;
#endif

#ifdef LINSOLVE
    float acum;
    int cont;
    unsigned int k = 0;
    #ifdef REUSE
    float x_new;
    do {
        acum = 0.0f;
        cont = 0;
        for (unsigned int i = 1; i < n + 1; i++) {
            unsigned int j = 1;
            #ifdef INV_M
            x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
            #else
            x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) / c;
            #endif

            if (ABS(x_new) > 1e-10f) {
                cont++;
                acum += ABS(x_new - x[IX(i, j)]);
            }
            x[IX(i, j)] = x_new;

            for (j = 2; j < n + 1; j++) {

                #ifdef INV_M
                x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
                #else
                    x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) / c;
                #endif

                if (ABS(x_new) > 1e-10f) {
                    cont++;
                    acum += ABS(x_new - x[IX(i, j)]);
                }
                x[IX(i, j)] = x_new;
            }
        }
        acum = acum / (float)cont;
        set_bnd(n, b, x);
        k++;
    } while (acum > 1e-6f && k < 20);
    #else

    float x_new;
    do {
        acum = 0.0f;
        cont = 0;
        for (unsigned int i = 1; i < n + 1; i++) {
            for (unsigned int j = 1; j < n + 1; j++) {
                #ifdef INV_M
                x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
                #else
                x_new = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) / c;
                #endif

                if (ABS(x_new) > 1e-5f) {
                    cont++;
                    acum += ABS(x_new - x[IX(i, j)]);
                }
                x[IX(i, j)] = x_new;
            }
        }
        acum = acum / (n * n);
        set_bnd(n, b, x);
        k++;
    } while (acum > 1e-5f && k < 20));
#endif
#else

#ifdef VECT_LINSOLVE
    lin_solve_vect(n + 2, b, x, x0, a, 1.0f / c);
#else
#ifdef PAR_LINSOLVE
    int offsetI = 0, offsetF = 0, alpha = 0, base = 0;
    float acum1, acum2, acumT ;
    unsigned int cont1, cont2, contT;
    unsigned int k = 0;
    float inv_c = 1.0f / c;

    do {
        k++;
        acum1 = 0.0f,acum2 = 0.0f,acumT = 0.0f;
        cont1 = 0,cont2 = 0,contT = 0;
        
        // Impar - Impar
        #pragma omp parallel shared(x,x0, a, b, inv_c, n, contT, acumT) private(base, offsetI, offsetF, alpha) 
        {
        base = (n * n / 2) + 1;
        offsetI = 0;
        offsetF = -1;
        alpha = -1;
        #pragma omp for reduction(+:cont1, acum1)
        for (size_t i = 1; i < n - 1; i += 2)
            lin_solve_single(n+2, i, base, offsetI, offsetF, &cont1, &acum1, alpha, x, x0, a, inv_c);
        
        /// Rojos ; Par - Par
        base = (n * n / 2) - 1;
        offsetI = 1;
        offsetF = 0;
        alpha = 1;

        #pragma omp for reduction(+:cont2, acum2)
        for (size_t i = 2; i < n - 1; i += 2)
            lin_solve_single(n+2, i, base, offsetI, offsetF, &cont2, &acum2, alpha, x, x0, a, inv_c);
        
        #pragma omp barrier
        acumT += acum1 + acum2;
        contT += cont1 + cont2;

        cont1 = 0,cont2 = 0; 
        acum1 = 0.0f,acum2 = 0.0f;        

        /// Negros ; Par - Impar
        offsetI = n * n / 2;
        offsetF = n * n / 2 - 1;
        base = -((n * n / 2) - 1);
        alpha = -1;

        #pragma omp for reduction(+:cont1, acum1)
        for (size_t i = 1; i < n - 1; i += 2)
            lin_solve_single(n+2, i, base, offsetI, offsetF, &cont1, &acum1, alpha, x, x0, a, inv_c);

        /// Negros ; Impar - Par
        base = -((n * n / 2) + 1);
        offsetI = n * n / 2 + 1;
        offsetF = n * n / 2;
        alpha = 1;

        #pragma omp for reduction(+:cont2, acum2)
        for (size_t i = 2; i < n - 1; i += 2)
            lin_solve_single(n+2, i, base, offsetI, offsetF, &cont2, &acum2, alpha, x, x0, a, inv_c);

        #pragma omp barrier
        acumT += acum1 + acum2;
        contT += cont1 + cont2;
        }
        set_bnd(n, b, x);
        
    } while (acumT / (float) contT > 1e-10f && k < 20);

#else
    for (unsigned int k = 0; k < 20; k++) {
        for (unsigned int i = 1; i < n + 1; i++) {
            for (unsigned int j = 1; j < n + 1; j++) {
                x[IX(i, j)] = (x0[IX(i, j)]
                               + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)]))
                    / c;
            }
        }
        set_bnd(n, b, x);
    }
#endif
#endif
#endif
}

static void diffuse(unsigned int n, boundary b, float* restrict x, const float* x0, float diff, float dt)
{
    float a = dt * diff * n * n;
    lin_solve(n, b, x, x0, a, 1 + 4 * a);
}

static void advect(unsigned int n, boundary b, float* restrict d, const float* restrict d0, const float* restrict u, const float* restrict v, float dt)
{
    int i0, i1, j0, j1;
    float x, y, s0, t0, s1, t1;

    float dt0 = dt * n;
    for (unsigned int i = 1; i < n + 1; i++) {
        for (unsigned int j = 1; j < n + 1; j++) {
            x = i - dt0 * u[IX(i, j)];
            y = j - dt0 * v[IX(i, j)];
            if (x < 0.5f) {
                x = 0.5f;
            } else if (x > n + 0.5f) {
                x = n + 0.5f;
            }
            i0 = (int)x;
            i1 = i0 + 1;
            if (y < 0.5f) {
                y = 0.5f;
            } else if (y > n + 0.5f) {
                y = n + 0.5f;
            }
            j0 = (int)y;
            j1 = j0 + 1;
            s1 = x - i0;
            s0 = 1 - s1;
            t1 = y - j0;
            t0 = 1 - t1;
            d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) + s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
        }
    }
    set_bnd(n, b, d);
}

static void project(unsigned int n, float* restrict u, float* restrict v, float* restrict p, float* restrict div)
{
    for (unsigned int i = 1; i < n + 1; i++) {
        for (unsigned int j = 1; j < n + 1; j++) {
            div[IX(i, j)] = -0.5f * (u[IX(i + 1, j)] - u[IX(i - 1, j)] + v[IX(i, j + 1)] - v[IX(i, j - 1)]) / n;
            p[IX(i, j)] = 0;
        }
    }
    set_bnd(n, NONE, div);
    set_bnd(n, NONE, p);

    lin_solve(n, NONE, p, div, 1, 4);

#pragma loop distribute(enable)
    for (unsigned int i = 1; i < n + 1; i++) {
        for (unsigned int j = 1; j < n + 1; j++) {
            u[IX(i, j)] -= 0.5f * n * (p[IX(i + 1, j)] - p[IX(i - 1, j)]);
            v[IX(i, j)] -= 0.5f * n * (p[IX(i, j + 1)] - p[IX(i, j - 1)]);
        }
    }
    set_bnd(n, VERTICAL, u);
    set_bnd(n, HORIZONTAL, v);
}

void dens_step(unsigned int n, float* restrict x, float* restrict x0, float* restrict u, float* restrict v, float diff, float dt)
{
    add_source(n, x, x0, dt);
    SWAP(x0, x);
    diffuse(n, NONE, x, x0, diff, dt);
    SWAP(x0, x);
    advect(n, NONE, x, x0, u, v, dt);
}

void vel_step(unsigned int n, float* restrict u, float* restrict v, float* restrict u0, float* restrict v0, float visc, float dt)
{

    add_source(n, u, u0, dt);
    add_source(n, v, v0, dt);
    SWAP(u0, u);
    diffuse(n, VERTICAL, u, u0, visc, dt);
    SWAP(v0, v);
    diffuse(n, HORIZONTAL, v, v0, visc, dt);
    project(n, u, v, u0, v0);
    SWAP(u0, u);
    SWAP(v0, v);
    advect(n, VERTICAL, u, u0, u0, v0, dt);
    advect(n, HORIZONTAL, v, v0, u0, v0, dt);
    project(n, u, v, u0, v0);
}
