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
#include <hdf5.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


/* likwid library */
#ifdef LIKWID_PERFMON
#include <likwid.h>
#else
#define LIKWID_MARKER_INIT
#define LIKWID_MARKER_THREADINIT
#define LIKWID_MARKER_SWITCH
#define LIKWID_MARKER_REGISTER(regionTag)
#define LIKWID_MARKER_START(regionTag)
#define LIKWID_MARKER_STOP(regionTag)
#define LIKWID_MARKER_CLOSE
#define LIKWID_MARKER_GET(regionTag, nevents, events, time, count)
#endif

/* global variables */
#ifndef N
#define N 64
#endif

/* macros */

// #define IX(i, j) ((i) + (N + 2) * (j))
// #define IX(i, j) ((i) * (N + 2) + (j))

#ifdef RB
static size_t rb_idx(size_t x, size_t y, size_t dim) {
    assert(dim % 2 == 0);
    size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    
    #ifdef RBC
    // Por columnas
    size_t offset = (x / 2) + y * (dim / 2);
    #else
    // Por filas
    size_t offset = (y / 2) + x * (dim / 2);
    #endif
    
    return base + offset;
}
    #define IX(x,y) (rb_idx((x),(y),(N+2)))
#else
    #define IX(i, j) ((i) + (N + 2) * (j))
#endif


#ifndef Ntimes
#define Ntimes 2048
#endif

/* external definitions (from solver.c) */
extern void dens_step(int n, float* x, float* x0, float* u, float* v, float diff, float dt);
extern void vel_step(int n, float* u, float* v, float* u0, float* v0, float visc, float dt);

static int count;
static float dt, diff, visc;
static float force, source;

static float *u, *u_prev;
static float *v, *v_prev;
static float *dens, *dens_prev;

#ifdef H5DATA
static char H5FILE_NAME[50];
#endif
static char FILE_NAME[50];
static FILE* fp;

/*
  ----------------------------------------------------------------------
   free/clear/allocate simulation data
  ----------------------------------------------------------------------
*/

#ifdef H5DATA
static int create_H5_2Ddata(char* H5FILE_NAME)
{
    hid_t file_id, dataspace_id;
    hsize_t dims[3];
    dims[0] = Ntimes;
    dims[1] = N + 2;
    dims[2] = N + 2;
    herr_t status;

    file_id = H5Fcreate(H5FILE_NAME, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    dataspace_id = H5Screate_simple(3, dims, NULL);
    hid_t dens_id = H5Dcreate(file_id, "dens", H5T_NATIVE_FLOAT, dataspace_id,
                              H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    hid_t u_id = H5Dcreate(file_id, "u", H5T_NATIVE_FLOAT, dataspace_id,
                           H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    hid_t v_id = H5Dcreate(file_id, "v", H5T_NATIVE_FLOAT, dataspace_id,
                           H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    status = H5Dclose(dens_id);
    status = H5Dclose(u_id);
    status = H5Dclose(v_id);
    status = H5Fclose(file_id);

    return status;
}

static int write_H5_2Ddata(hid_t file_id, char* DATASET_NAME, float* dset_data, int it)
{
    hsize_t offset[3] = { it, 0, 0 };
    hsize_t count[3] = { 1, N + 2, N + 2 };
    hsize_t slabsize[3] = { N + 2, N + 2 };
    herr_t status;
    hid_t dataset_id = H5Dopen(file_id, DATASET_NAME, H5P_DEFAULT);
    hid_t dataspace_id = H5Dget_space(dataset_id);

    hid_t memspace_id = H5Screate_simple(2, slabsize, NULL);
    status = H5Sselect_hyperslab(dataspace_id, H5S_SELECT_SET, offset, NULL, count, NULL);
    status = H5Dwrite(dataset_id, H5T_NATIVE_FLOAT, memspace_id, dataspace_id, H5P_DEFAULT, dset_data);
    status = H5Sclose(dataspace_id);
    status = H5Sclose(memspace_id);
    status = H5Dclose(dataset_id);

    return status;
}

static int writeFields(char* H5FILE_NAME, float* dens, float* u, float* v, int offset)
{
    herr_t status;
    hid_t file_id = H5Fopen(H5FILE_NAME, H5F_ACC_RDWR, H5P_DEFAULT);
    write_H5_2Ddata(file_id, "dens", dens, offset);
    write_H5_2Ddata(file_id, "u", u, offset);
    write_H5_2Ddata(file_id, "v", v, offset);
    status = H5Fclose(file_id);
    return status;
}

#endif

static void free_data(void)
{
    if (u) {
        free(u);
    }
    if (v) {
        free(v);
    }
    if (u_prev) {
        free(u_prev);
    }
    if (v_prev) {
        free(v_prev);
    }
    if (dens) {
        free(dens);
    }
    if (dens_prev) {
        free(dens_prev);
    }
    if (fp) {
        fclose(fp);
    }
}

static void clear_data(void)
{
    int i, size = (N + 2) * (N + 2);

    for (i = 0; i < size; i++) {
        u[i] = v[i] = u_prev[i] = v_prev[i] = dens[i] = dens_prev[i] = 0.0f;
    }
}

static int allocate_data(void)
{
    int size = (N + 2) * (N + 2);

    u = (float*)malloc(size * sizeof(float));
    v = (float*)malloc(size * sizeof(float));
    u_prev = (float*)malloc(size * sizeof(float));
    v_prev = (float*)malloc(size * sizeof(float));
    dens = (float*)malloc(size * sizeof(float));
    dens_prev = (float*)malloc(size * sizeof(float));
    fp = fopen(FILE_NAME, "w");

    if (!u || !v || !u_prev || !v_prev || !dens || !dens_prev || !fp) {
        // printf("%d, %d, %d, %d, %d, %d, %d\n", u == NULL, v == NULL, u_prev == NULL, v_prev == NULL, dens == NULL, dens_prev == NULL, fp == NULL);
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

static void one_step(double* rct, double *vel, double* dns)
{
    // static int times = 1;
    static double start_t = 0.0;
    // static double one_second = 0.0;
    static double react_ns_p_cell = 0.0;
    static double vel_ns_p_cell = 0.0;
    static double dens_ns_p_cell = 0.0;

    start_t = wtime();

    LIKWID_MARKER_START("REACT");
    react(dens_prev, u_prev, v_prev);
    LIKWID_MARKER_STOP("REACT");
    react_ns_p_cell += (wtime() - start_t);

    start_t = wtime();

    LIKWID_MARKER_START("VEL");
    vel_step(N, u, v, u_prev, v_prev, visc, dt);
    LIKWID_MARKER_STOP("VEL");

    vel_ns_p_cell += (wtime() - start_t);

    start_t = wtime();

    LIKWID_MARKER_START("DENS");
    dens_step(N, dens, dens_prev, u, v, diff, dt);
    LIKWID_MARKER_STOP("DENS");

    dens_ns_p_cell += (wtime() - start_t) / (N * N);

#ifdef H5DATA
    // int status = 
    writeFields(H5FILE_NAME, dens, u, v, it);
#endif

    *rct = react_ns_p_cell;
    *vel = vel_ns_p_cell;
    *dns = dens_ns_p_cell;
}


/*
  ----------------------------------------------------------------------
   main --- main routine
  ----------------------------------------------------------------------
*/

int main(int argc, char** argv)
{
    int i = 0;
    count = 0;
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
        strcpy(FILE_NAME, "RunTime.dat");
        fprintf(stderr, "Using defaults : N=%d dt=%g diff=%g visc=%g force = %g source=%g\n",
                N, dt, diff, visc, force, source);
    } else {
        dt = atof(argv[2]);
        diff = atof(argv[3]);
        visc = atof(argv[4]);
        force = atof(argv[5]);
        source = atof(argv[6]);
        strcpy(FILE_NAME, argv[7]);
    }

    if (!allocate_data()) {
        exit(1);
    }
    clear_data();


    // Likwid Marker API initialization.
    LIKWID_MARKER_INIT;
    LIKWID_MARKER_THREADINIT;

    // Register regions:
    LIKWID_MARKER_REGISTER("TOTAL");
    LIKWID_MARKER_REGISTER("REACT");
    LIKWID_MARKER_REGISTER("VEL");
    LIKWID_MARKER_REGISTER("DENS");


#ifdef H5DATA
    strcpy(H5FILE_NAME, "data.h5");

    // int status = 
    create_H5_2Ddata(H5FILE_NAME);
#endif

    LIKWID_MARKER_START("TOTAL");

    double rct,vel,dns;

    for (i = 0; i < Ntimes; i++)
        one_step(&rct, &vel, &dns);

    printf("# CELL_MS: %f\n", N*N * Ntimes / (rct + vel + dns) * 1e-3);

    LIKWID_MARKER_STOP("TOTAL");

    LIKWID_MARKER_CLOSE;

    free_data();

    exit(0);
}
