#include "solver.h"
#include <assert.h>
#include <stddef.h>
#include <stdio.h>
#include <cuda.h>
#include "helper_cuda.h"

/** Constantes */
#ifndef SIZE
#define SIZE 256
#endif

#ifndef BLOCK_SIZE
#define BLOCK_SIZE 128
#endif

#ifndef BLOCK_SIZE_2D
#define BLOCK_SIZE_2D 32
#endif

#ifndef RB_BLOCK
#define RB_BLOCK 32
#endif

typedef enum boundary { NONE = 0, VERTICAL = 1, HORIZONTAL = 2 } boundary;

/** Utiles */
#define ABS(x) x < 0.0f ? -x : x

//#define IX(i, j) ((i) + (n + 2) * (j))
__device__ size_t IX(size_t x, size_t y)
{
     size_t dim = SIZE + 2;
     assert(dim % 2 == 0);
     size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
     size_t offset = (y / 2) + x * (dim / 2);
     return base + offset;
}

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

__global__ void add_source(uint n, float* x, const float* s, float dt) {
    uint i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < (n + 2) * (n + 2))
        x[i] += dt * s[i];
}

static void launch_add_source(uint n, float* x, const float* s, float dt) {
    dim3 block(BLOCK_SIZE);
    dim3 grid(div_ceil<uint>((n + 2) * (n + 2), BLOCK_SIZE));
    add_source<<<grid,block>>>(n, x, s, dt);
    getLastCudaError("add_source() kernel failed");
}


__global__
void set_bnd(uint n, boundary b, float* x, bool* status)
{
    uint i = blockDim.x * blockIdx.x + threadIdx.x + 1;
    if (i < n + 1){
        x[IX(0, i)] = b == VERTICAL ? -x[IX(1, i)] : x[IX(1, i)];
        x[IX(n + 1, i)] = b == VERTICAL ? -x[IX(n, i)] : x[IX(n, i)];
        x[IX(i, 0)] = b == HORIZONTAL ? -x[IX(i, 1)] : x[IX(i, 1)];
        x[IX(i, n + 1)] = b == HORIZONTAL ? -x[IX(i, n)] : x[IX(i, n)];
    }
    // if (i == 1) {   // calculo esquina 0 0 y marco SI
    //     x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
    //     status[0] = true;
    // } else if (i == n) { // calculo esquina n+1 n+1 y marco ID
    //     x[IX(n + 1, n + 1)] = 0.5f * (x[IX(n, n + 1)] + x[IX(n + 1, n)]);
    //     status[1] = true;
    // }

    // if (status[0] && status[1] && !status[2]) {
    //     x[IX(0, n + 1)] = 0.5f * (x[IX(1, n + 1)] + x[IX(0, n)]);
    //     x[IX(n + 1, 0)] = 0.5f * (x[IX(n, 0)] + x[IX(n + 1, 1)]);
    //     status[2] = true;
    //     // printf("ENTRE PADRE! \n");
    // }
}

static void launch_set_bnd(uint n, boundary b, float* x){
    dim3 block(BLOCK_SIZE);
    dim3 grid(div_ceil<uint>(n, BLOCK_SIZE));
    bool *status = nullptr;
    checkCudaErrors(cudaMalloc(&status, 3 * sizeof(bool)));
    checkCudaErrors(cudaMemset(status, 0, 3 * sizeof(bool)));
    set_bnd<<<grid,block>>>(n,b,x,status);
    getLastCudaError("set_bnd() kernel failed");
	checkCudaErrors(cudaDeviceSynchronize());
}

__global__
void lin_solve_step(uint n, uint * cont, float * acum, float *x, const float *x0, float a, float inv_c, bool rojo)
{
    // 2D ; 1 elemento por hilo no redblack. No entiendo porque funciona, pero lo hace.
    // int i = blockDim.x * blockIdx.x + threadIdx.x + 1;
    // int j = blockDim.y * blockIdx.y + threadIdx.y + 1;
    // if(i <= n && j <= n)
    //     x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;

    // 2D ; 1 elemento por hilo. No anda ni para atras.
    
    int ri = blockDim.x * blockIdx.x + threadIdx.x + 1; // 1 .. SIZE
    int rj = blockDim.y * blockIdx.y + threadIdx.y + 1; // 1 .. SIZE/2
    
    int i, j;
    if (ri <= n && rj <= n / 2) {
        uint idx;
	    i = ri;
        if (rojo)
        {
            if (ri % 2 == 0)
	        {
                j = 2 * rj;  
                idx = IX(i,j);
                x[idx] = (x0[idx] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
            } 
            else
            {
                j = 2 * rj - 1;
                idx = IX(i,j);
                x[idx] = (x0[idx] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
            } 
        }
        else
        {
            if (ri % 2 == 0)
            {
                j = 2 * rj - 1;
                idx = IX(i,j);
                x[idx] = (x0[idx] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
            } 
            else
            {
                j = 2 * rj;  
                idx = IX(i,j);
                x[idx] = (x0[idx] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] + x[IX(i, j - 1)] + x[IX(i, j + 1)])) * inv_c;
            } 
        }
    }
}
    

static void launch_lin_solve_step(uint n, uint * cont, float * acum, float *x, const float *x0, float a, float inv_c, bool rojo)
{    
    // 2D ; 1 elemento por hilo.
    dim3 block(RB_BLOCK, RB_BLOCK / 2);
    dim3 grid(div_ceil(n, block.x), div_ceil(n/2, block.y));

    lin_solve_step<<<grid, block>>>(n, cont, acum, x, x0, a, inv_c, rojo);
    getLastCudaError("lin_solve_step() kernel failed");
}


static void lin_solve(uint n, boundary b, float* x, const float* x0, float a, float c)
{
    uint k = 0;
    float inv_c = 1.0f / c;

    do {
        k++;
        launch_lin_solve_step(n, nullptr, nullptr, x, x0, a, inv_c, true);
        checkCudaErrors(cudaDeviceSynchronize());

        launch_lin_solve_step(n, nullptr, nullptr, x, x0, a, inv_c, false);
        checkCudaErrors(cudaDeviceSynchronize());

        launch_set_bnd(n, b, x);
    } while (k < 20);
}

static void diffuse(uint n, boundary b, float* x, const float* x0, float diff, float dt)
{
    float a = dt * diff * n * n;
    lin_solve(n, b, x, x0, a, 1 + 4 * a);
}

__global__
void advect_step(uint n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt) {
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

static void launch_advect_step(uint n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt) {
    dim3 block(BLOCK_SIZE_2D,BLOCK_SIZE_2D);
    dim3 grid(div_ceil(n, block.x), div_ceil(n, block.y));
    advect_step<<<grid, block>>>(n, b, d, d0, u, v, dt);
    getLastCudaError("advect_step() kernel failed");
    checkCudaErrors(cudaDeviceSynchronize());
}

static void advect(uint n, boundary b, float* d, const float* d0, const float* u, const float* v, float dt)
{
    launch_advect_step(n,b,d,d0,u,v,dt);
    launch_set_bnd(n, b, d);
}

__global__
void pre_project(uint n, float* u, float* v, float* p, float* div){
    uint i = blockDim.x * blockIdx.x + threadIdx.x + 1;
    uint j = blockDim.y * blockIdx.y + threadIdx.y + 1;
        
    if (i < n + 1 && j < n + 1) {
        div[IX(i, j)] = -0.5f * (u[IX(i + 1, j)] - u[IX(i - 1, j)] + v[IX(i, j + 1)] - v[IX(i, j - 1)]) / n;
        p[IX(i, j)] = 0;
    }
}

static void launch_pre_project(uint n, float* u, float* v, float* p, float* div) {
    dim3 block(BLOCK_SIZE_2D,BLOCK_SIZE_2D);
    dim3 grid(div_ceil(n, block.x), div_ceil(n, block.y));
    pre_project<<<grid, block>>>(n, u, v, p, div);
    getLastCudaError("pre_project() kernel failed");
}

__global__
void post_project(uint n, float* u, float* v, float* p, float* div){
    int i = blockDim.x * blockIdx.x + threadIdx.x + 1;
    int j = blockDim.y * blockIdx.y + threadIdx.y + 1;
    if (i < n + 1 && j < n + 1) {
        u[IX(i, j)] -= 0.5f * n * (p[IX(i + 1, j)] - p[IX(i - 1, j)]);
        v[IX(i, j)] -= 0.5f * n * (p[IX(i, j + 1)] - p[IX(i, j - 1)]);
    }
}

static void launch_post_project(uint n, float* u, float* v, float* p, float* div) {
    dim3 block(BLOCK_SIZE_2D,BLOCK_SIZE_2D);
    dim3 grid(div_ceil(n, block.x), div_ceil(n, block.y));
    post_project<<<grid, block>>>(n, u, v, p, div);
    getLastCudaError("post_project() kernel failed");
}

static void project(uint n, float* u, float* v, float* p, float* div)
{
    launch_pre_project(n,u,v,p,div);
    checkCudaErrors(cudaDeviceSynchronize());
    launch_set_bnd(n, NONE, div);
    launch_set_bnd(n, NONE, p);
    lin_solve(n, NONE, p, div, 1, 4);
    launch_post_project(n,u,v,p,div);
    checkCudaErrors(cudaDeviceSynchronize());
    launch_set_bnd(n, VERTICAL, u);
    launch_set_bnd(n, HORIZONTAL, v);
}

void dens_step(uint n, float* x, float* x0, float* u, float* v, float diff, float dt)
{
    launch_add_source(n, x, x0, dt);
    checkCudaErrors(cudaDeviceSynchronize());
    SWAP(x0, x);
    diffuse(n, NONE, x, x0, diff, dt);
    SWAP(x0, x);
    advect(n, NONE, x, x0, u, v, dt);
}

void vel_step(uint n, float* u, float* v, float* u0, float* v0, float visc, float dt)
{
    launch_add_source(n, u, u0, dt);
    launch_add_source(n, v, v0, dt);
    checkCudaErrors(cudaDeviceSynchronize());
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
