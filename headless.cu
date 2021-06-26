/*
  ======================================================================
   demo.c --- protoype to show off the simple solver
  ----------------------------------------------------------------------
   Author : Jos Stam (jstam@aw.sgi.com)
   Creation Date : Jan 9 2003

   Description:

	This code is a simple prototype that demonstrates how to use the
	code provided in my GDC2003 paper entitles "Real-Time Fluid Dynamics
	for Games". This code uses OpenGL and GLUT for graphics and interface

  =======================================================================
*/

#include "wtime.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>
#include "helper_cuda.h"
#include "solver.h"

/* global variables */
#ifndef N
#define N 256
#endif

__host__ __device__
static size_t IX(size_t x, size_t y)
{
    size_t dim = N + 2;
    assert(dim % 2 == 0);
    size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    size_t offset = (y / 2) + x * (dim / 2);
    return base + offset;
}

#ifndef Ntimes
#define Ntimes 2048
#endif

static float dt, diff, visc;
static float force, source;

static float *u, *u_prev;
static float *v, *v_prev;
static float *dens, *dens_prev;

static void free_data(void)
{
    
    if (u)    
        checkCudaErrors(cudaFree(u)); 
    if (v)
        checkCudaErrors(cudaFree(v)); 
    if (u_prev)
        checkCudaErrors(cudaFree(u_prev));
    if (v_prev)
        checkCudaErrors(cudaFree(v_prev));
    if (dens)
        checkCudaErrors(cudaFree(dens)); 
    if (dens_prev)
        checkCudaErrors(cudaFree(dens_prev));
}

// Allocate and clean! 
static int allocate_data(void)
{
    int size = (N + 2) * (N + 2);
    /* Allocate magic mem in CPU & GPU. */ 
    checkCudaErrors(cudaMallocManaged(&u,         size * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&v,         size * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&u_prev,    size * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&v_prev,    size * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&dens,      size * sizeof(float)));
    checkCudaErrors(cudaMallocManaged(&dens_prev, size * sizeof(float)));

    checkCudaErrors(cudaMemset(u,         0, size * sizeof(float)));
    checkCudaErrors(cudaMemset(v,         0, size * sizeof(float)));
    checkCudaErrors(cudaMemset(u_prev,    0, size * sizeof(float)));
    checkCudaErrors(cudaMemset(v_prev,    0, size * sizeof(float)));
    checkCudaErrors(cudaMemset(dens,      0, size * sizeof(float)));
    checkCudaErrors(cudaMemset(dens_prev, 0, size * sizeof(float)));

    if (!u || !v || !u_prev || !v_prev || !dens || !dens_prev) {
        fprintf(stderr, "cannot allocate data\n");
        return (0);
    }
    return (1);
}

static void react(float* d, float* u, float* v)
{
    int i, size = (N + 2) * (N + 2);
    float max_velocity2 = 0.0f;
    float max_density = 0.0f;

    max_velocity2 = max_density = 0.0f;
    for (i = 0; i < size; i++) {
        if (max_velocity2 < u[i] * u[i] + v[i] * v[i]) {
            max_velocity2 = u[i] * u[i] + v[i] * v[i];
        }
        if (max_density < d[i]) {
            max_density = d[i];
        }
    }

    for (i = 0; i < size; i++) {
        u[i] = v[i] = d[i] = 0.0f;
    }

    if (max_velocity2 < 0.0000005f) {
        u[IX(N / 2, N / 2)] = force * 10.0f;
        v[IX(N / 2, N / 2)] = force * 10.0f;
    }

    if (max_density < 1.0f) {
        d[IX(N / 2, N / 2)] = source * 10.0f;
    }

    return;
}

static void one_step(double* rct, double* vel, double* dns)
{
    float start_t = 0.0;

    start_t = wtime();
    react(dens_prev, u_prev, v_prev);
    *rct += (wtime() - start_t);

    start_t = wtime();
    vel_step(N, u, v, u_prev, v_prev, visc, dt);
    *vel += (wtime() - start_t);

    start_t = wtime();
    dens_step(N, dens, dens_prev, u, v, diff, dt);
    *dns += (wtime() - start_t);
}


/*
  ----------------------------------------------------------------------
   main --- main routine
  ----------------------------------------------------------------------
*/

int main(int argc, char** argv)
{
    int i = 0;
    if (argc != 1 && argc != 8) {
        fprintf(stderr, "usage : %s N dt diff visc force source\n", argv[0]);
        fprintf(stderr, "where:\n");
        fprintf(stderr, "\t N      : grid resolution\n");
        fprintf(stderr, "\t dt     : time step\n");
        fprintf(stderr, "\t diff   : diffusion rate of the density\n");
        fprintf(stderr, "\t visc   : viscosity of the fluid\n");
        fprintf(stderr, "\t force  : scales the mouse movement that generate a force\n");
        fprintf(stderr, "\t source : amount of density that will be deposited\n");
        fprintf(stderr, "\t file   : output file name\n");
        exit(1);
    }

    if (argc == 1) {
        dt = 0.1f;
        diff = 0.0f;
        visc = 0.0f;
        force = 5.0f;
        source = 100.0f;
        fprintf(stderr, "Using defaults : N=%d dt=%g diff=%g visc=%g force=%g source=%g\n",
                N, dt, diff, visc, force, source);
    } else {
        dt = atof(argv[2]);
        diff = atof(argv[3]);
        visc = atof(argv[4]);
        force = atof(argv[5]);
        source = atof(argv[6]);
    }

    if (!allocate_data()) {
        exit(1);
    }

    double rct, vel, dns;

    for (i = 0; i < Ntimes; i++)
        one_step(&rct, &vel, &dns);

    long long unsigned int total = (long long unsigned int)N * (long long unsigned int)N * (long long unsigned int)Ntimes;
    printf("# CELL_MS: %f\n", (total / (rct + vel + dns)) * 1e-3);

    free_data();

    exit(0);
}
