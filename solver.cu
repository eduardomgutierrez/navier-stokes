
#include "solver.h"
#include <assert.h>
#include <stddef.h>
#include <stdio.h>
#include <cuda.h>
#include "helper_cuda.h"

/** Utiles */
#define ABS(x) x < 0.0f ? -x : x

__host__ __device__
static size_t rb_idx(size_t x, size_t y, size_t dim)
{
    assert(dim % 2 == 0);
    size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    size_t offset = (y / 2) + x * (dim / 2);
    return base + offset;
}

#define IX(x, y) (rb_idx((x), (y), (N + 2)))

// Simplificar
#define SWAP(x0, x)      \
    {                    \
        float* tmp = x0; \
        x0 = x;          \
        x = tmp;         \
    }

template <typename T>
T div_ceil(T a, T b) {
    return (a + b - 1) / b;
}

/** Constantes */
#ifndef N
#define N 256
#endif

#ifndef BLOCK_SIZE
#define BLOCK_SIZE 128
#endif

typedef enum boundary {
    NONE = 0,
    VERTICAL = 1,
    HORIZONTAL = 2 
} boundary;

__global__
void add_source(unsigned int n, float* x, const float* s, float dt) {
    uint i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < (n + 2) * (n + 2)) x[i] += dt * s[i];
}

static void launch_add_source(unsigned int n, float* x, const float* s, float dt) {
    dim3 block(BLOCK_SIZE);
    dim3 grid(div_ceil<uint>(n + 2 * n + 2, BLOCK_SIZE));
    add_source<<<grid,block>>>(n,x,s,dt);
    getLastCudaError("add_source() kernel failed");
	checkCudaErrors(cudaDeviceSynchronize());
}

__global__
void set_bnd(unsigned int n, boundary b, float* x)
{
    uint i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < n + 1){
        x[IX(0, i)] = b == VERTICAL ? -x[IX(1, i)] : x[IX(1, i)];
        x[IX(n + 1, i)] = b == VERTICAL ? -x[IX(n, i)] : x[IX(n, i)];
        x[IX(i, 0)] = b == HORIZONTAL ? -x[IX(i, 1)] : x[IX(i, 1)];
        x[IX(i, n + 1)] = b == HORIZONTAL ? -x[IX(i, n)] : x[IX(i, n)];
    }   
}

static void launch_set_bnd(unsigned int n, boundary b, float* x){
    dim3 block(BLOCK_SIZE);
    dim3 grid(div_ceil<uint>(n, BLOCK_SIZE));
    set_bnd<<<grid,block>>>(n,b,x);
    getLastCudaError("set_bnd() kernel failed");
	checkCudaErrors(cudaDeviceSynchronize());
}

static void set_corners(unsigned int n, boundary b, float* x) {
    x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
    x[IX(0, n + 1)] = 0.5f * (x[IX(1, n + 1)] + x[IX(0, n)]);
    x[IX(n + 1, 0)] = 0.5f * (x[IX(n, 0)] + x[IX(n + 1, 1)]);
    x[IX(n + 1, n + 1)] = 0.5f * (x[IX(n, n + 1)] + x[IX(n + 1, n)]);
}

static void lin_solve(unsigned int n, boundary b, float* x, const float* x0, float a, float c)
{
//     int offsetI = 0, offsetF = 0, alpha = 0, base = 0;
//     float acum1, acum2, acumT ;
//     unsigned int cont1, cont2, contT;
//     unsigned int k = 0;
//     float inv_c = 1.0f / c;

//     do {
//         k++;
//         acum1 = 0.0f,acum2 = 0.0f,acumT = 0.0f;
//         cont1 = 0,cont2 = 0,contT = 0;
        
//         // Impar - Impar
//         #pragma omp parallel shared(x,x0, a, b, inv_c, n, contT, acumT) private(base, offsetI, offsetF, alpha) 
//         {
//         base = (n * n / 2) + 1;
//         offsetI = 0;
//         offsetF = -1;
//         alpha = -1;
//         #pragma omp for reduction(+:cont1, acum1)
//         for (size_t i = 1; i < n - 1; i += 2)
//             lin_solve_single(n+2, i, base, offsetI, offsetF, &cont1, &acum1, alpha, x, x0, a, inv_c);
        
//         /// Rojos ; Par - Par
//         base = (n * n / 2) - 1;
//         offsetI = 1;
//         offsetF = 0;
//         alpha = 1;

//         #pragma omp for reduction(+:cont2, acum2)
//         for (size_t i = 2; i < n - 1; i += 2)
//             lin_solve_single(n+2, i, base, offsetI, offsetF, &cont2, &acum2, alpha, x, x0, a, inv_c);
        
//         #pragma omp barrier
//         acumT += acum1 + acum2;
//         contT += cont1 + cont2;

//         cont1 = 0,cont2 = 0; 
//         acum1 = 0.0f,acum2 = 0.0f;        

//         /// Negros ; Par - Impar
//         offsetI = n * n / 2;
//         offsetF = n * n / 2 - 1;
//         base = -((n * n / 2) - 1);
//         alpha = -1;

//         #pragma omp for reduction(+:cont1, acum1)
//         for (size_t i = 1; i < n - 1; i += 2)
//             lin_solve_single(n+2, i, base, offsetI, offsetF, &cont1, &acum1, alpha, x, x0, a, inv_c);

//         /// Negros ; Impar - Par
//         base = -((n * n / 2) + 1);
//         offsetI = n * n / 2 + 1;
//         offsetF = n * n / 2;
//         alpha = 1;

//         #pragma omp for reduction(+:cont2, acum2)
//         for (size_t i = 2; i < n - 1; i += 2)
//             lin_solve_single(n+2, i, base, offsetI, offsetF, &cont2, &acum2, alpha, x, x0, a, inv_c);

//         #pragma omp barrier
//         acumT += acum1 + acum2;
//         contT += cont1 + cont2;
//         }
//         set_bnd(n, b, x);s
        
//     } while (acumT / (float) contT > 1e-10f && k < 20);

// #else
    for (unsigned int k = 0; k < 20; k++) {
        for (unsigned int i = 1; i < n + 1; i++) {
            for (unsigned int j = 1; j < n + 1; j++) {
                x[IX(i, j)] = (x0[IX(i, j)]
                               + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)]))
                    / c;
            }
        }
        launch_set_bnd(n, b, x);
        set_corners(n, b, x);
    }
}

static void launch_lin_solve(unsigned int n, boundary b, float* x, const float* x0, float a, float c) {
    // dim3 block(1,1);
    // dim3 grid(1,1);
    // pre_project<<<grid, block>>>(n, u, v, p, div);
    // getLastCudaError("pre_project() kernel failed");
    // checkCudaErrors(cudaDeviceSynchronize());
}


static void diffuse(unsigned int n, boundary b, float* x, const float* x0, float diff, float dt)
{
    float a = dt * diff * n * n;
    launch_lin_solve(n, b, x, x0, a, 1 + 4 * a);
}

__global__
void advect_step(unsigned int n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt) {
    int i0, i1, j0, j1;
    float x, y, s0, t0, s1, t1;

    float dt0 = dt * n;

    int i = blockDim.x * blockIdx.x + threadIdx.x;
    int j = blockDim.y * blockIdx.y + threadIdx.y;

    if (i < n+1 && j < n+1) {
        x = i - dt0 * u[IX(i, j)];
        y = j - dt0 * v[IX(i, j)];
        if (x < 0.5f)
            x = 0.5f;
        else if (x > n + 0.5f)
            x = n + 0.5f;
        i0 = (int)x;
        i1 = i0 + 1;
        if (y < 0.5f)
            y = 0.5f;
        else if (y > n + 0.5f)
            y = n + 0.5f;
        j0 = (int)y;
        j1 = j0 + 1;
        s1 = x - i0;
        s0 = 1 - s1;
        t1 = y - j0;
        t0 = 1 - t1;
        d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) + s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
    }
}

static void launch_advect_step(unsigned int n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt) {
    dim3 block(1,1);
    dim3 grid(1,1);
    advect_step<<<grid, block>>>(n, b, d, d0, u, v, dt);
    getLastCudaError("advect_step() kernel failed");
    checkCudaErrors(cudaDeviceSynchronize());
}

static void advect(unsigned int n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt)
{
    launch_advect_step(n,b,d,d0,u,v,dt);
    launch_set_bnd(n, b, d);
    set_corners(n, b, d);
}

__global__
void pre_project(unsigned int n, float* u, float* v, float* p, float* div){
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    int j = blockDim.y * blockIdx.y + threadIdx.y;
    if (i < n + 1 && j < n + 1) {
        div[IX(i, j)] = -0.5f * (u[IX(i + 1, j)] - u[IX(i - 1, j)] + v[IX(i, j + 1)] - v[IX(i, j - 1)]) / n;
        p[IX(i, j)] = 0;
    }    
}

static void launch_pre_project(unsigned int n, float* u, float* v, float* p, float* div) {
    dim3 block(1,1);
    dim3 grid(1,1);
    pre_project<<<grid, block>>>(n, u, v, p, div);
    getLastCudaError("pre_project() kernel failed");
    checkCudaErrors(cudaDeviceSynchronize());
}

__global__
void post_project(unsigned int n, float* u, float* v, float* p, float* div){
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    int j = blockDim.y * blockIdx.y + threadIdx.y;
    if (i < n + 1 && j < n + 1) {
        u[IX(i, j)] -= 0.5f * n * (p[IX(i + 1, j)] - p[IX(i - 1, j)]);
        v[IX(i, j)] -= 0.5f * n * (p[IX(i, j + 1)] - p[IX(i, j - 1)]);
    }
}

static void launch_post_project(unsigned int n, float* u, float* v, float* p, float* div) {
    dim3 block(1,1);
    dim3 grid(1,1);
    pre_project<<<grid, block>>>(n, u, v, p, div);
    getLastCudaError("post_project() kernel failed");
    checkCudaErrors(cudaDeviceSynchronize());
}

static void project(unsigned int n, float* u, float* v, float* p, float* div)
{
    launch_pre_project(n,u,v,p,div);

    launch_set_bnd(n, NONE, div);
    set_corners(n, NONE, div);

    launch_set_bnd(n, NONE, p);
    set_corners(n, NONE, p);

    launch_lin_solve(n, NONE, p, div, 1, 4);

    launch_post_project(n,u,v,p,div);
    
    launch_set_bnd(n, VERTICAL, u);
    set_corners(n, VERTICAL, u);

    launch_set_bnd(n, HORIZONTAL, v);
    set_corners(n, HORIZONTAL, v);
}

void dens_step(unsigned int n, float* x, float* x0, float* u, float* v, float diff, float dt)
{
    launch_add_source(n, x, x0, dt);
    SWAP(x0, x);
    diffuse(n, NONE, x, x0, diff, dt);
    SWAP(x0, x);
    advect(n, NONE, x, x0, u, v, dt);
}

void vel_step(unsigned int n, float* u, float* v, float* u0, float* v0, float visc, float dt)
{
    launch_add_source(n, u, u0, dt);
    launch_add_source(n, v, v0, dt);
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
