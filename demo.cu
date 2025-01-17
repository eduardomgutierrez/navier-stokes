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

#include <GL/glut.h>
#include <stdio.h>
#include <stdlib.h>

#include "solver.h"
#include "wtime.h"
#include <assert.h>

#include "helper_cuda.h"

/* macros */
#ifndef SIZE
#define SIZE 256
#endif

// #ifdef RB
static size_t IX(size_t x, size_t y)
{   
    size_t dim = SIZE + 2;
    assert(dim % 2 == 0);
    size_t base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    size_t offset = (y / 2) + x * (dim / 2);
    return base + offset;
}
// #else
// #define IX(i, j) ((i) + (SIZE + 2) * (j))
// #endif


/* global variables */

// static int SIZE;
static float dt, diff, visc;
static float force, source;
static int dvel;

static float *u, *v, *u_prev, *v_prev;
static float *dens, *dens_prev;

static int win_id;
static int win_x, win_y;
static int mouse_down[3];
static int omx, omy, mx, my;

/*
  ----------------------------------------------------------------------
   free/clear/allocate simulation data
  ----------------------------------------------------------------------
*/

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

static void clear_data(void)
{
    int i, size = (SIZE + 2) * (SIZE + 2);

    for (i = 0; i < size; i++) {
        u[i] = v[i] = u_prev[i] = v_prev[i] = dens[i] = dens_prev[i] = 0.0f;
    }
}

static int allocate_data(void)
{
    int size = (SIZE + 2) * (SIZE + 2);
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


/*
  ----------------------------------------------------------------------
   OpenGL specific drawing routines
  ----------------------------------------------------------------------
*/

static void pre_display(void)
{
    glViewport(0, 0, win_x, win_y);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0.0, 1.0, 0.0, 1.0);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

static void post_display(void)
{
    glutSwapBuffers();
}

static void draw_velocity(void)
{
    int i, j;
    float x, y, h;

    h = 1.0f / SIZE;

    glColor3f(1.0f, 1.0f, 1.0f);
    glLineWidth(1.0f);

    glBegin(GL_LINES);

    for (i = 1; i <= SIZE; i++) {
        x = (i - 0.5f) * h;
        for (j = 1; j <= SIZE; j++) {
            y = (j - 0.5f) * h;

            glVertex2f(x, y);
            glVertex2f(x + u[IX(i, j)], y + v[IX(i, j)]);
        }
    }

    glEnd();
}

static void draw_density(void)
{
    int i, j;
    float x, y, h, d00, d01, d10, d11;

    h = 1.0f / SIZE;

    glBegin(GL_QUADS);

    for (i = 0; i <= SIZE; i++) {
        x = (i - 0.5f) * h;
        for (j = 0; j <= SIZE; j++) {
            y = (j - 0.5f) * h;

            d00 = dens[IX(i, j)];
            d01 = dens[IX(i, j + 1)];
            d10 = dens[IX(i + 1, j)];
            d11 = dens[IX(i + 1, j + 1)];

            glColor3f(d00, d00, d00);
            glVertex2f(x, y);
            glColor3f(d10, d10, d10);
            glVertex2f(x + h, y);
            glColor3f(d11, d11, d11);
            glVertex2f(x + h, y + h);
            glColor3f(d01, d01, d01);
            glVertex2f(x, y + h);
        }
    }

    glEnd();
}

/*
  ----------------------------------------------------------------------
   relates mouse movements to forces sources
  ----------------------------------------------------------------------
*/

static void react(float* d, float* u, float* v)
{
    int i, j, size = (SIZE + 2) * (SIZE + 2);

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

    unsigned int sources = SIZE * 4 / 64;
    unsigned int total = sources / 4;
    assert(sources % 4 == 0);

    if (max_velocity2 < 0.0000005f) {

        #ifdef PROP_SOURCES
        unsigned int offset = 5;
        for (unsigned int count = 0; count < total - 1 && offset < SIZE / 2; count++, offset += sources) {
            if (!(count % 2)) {
                u[IX(1 + offset, 1 + offset)] = force * 10.0f;
                v[IX(1 + offset, 1 + offset)] = force * 10.0f;

                u[IX((SIZE + 1) - offset, (SIZE + 1) - offset)] = force * -10.0f;
                v[IX((SIZE + 1) - offset, (SIZE + 1) - offset)] = force * -10.0f;

                u[IX((SIZE + 1) - offset, 1 + offset)] = force * -10.0f;
                v[IX((SIZE + 1) - offset, 1 + offset)] = force * 10.0f;

                u[IX(1 + offset, (SIZE + 1) - offset)] = force * 10.0f;
                v[IX(1 + offset, (SIZE + 1) - offset)] = force * -10.0f;

            } else {
                u[IX(1 + offset, SIZE / 2)] = force * 10.0f;
                u[IX((SIZE + 1) - offset, SIZE / 2)] = source * -10.0f;
                v[IX(SIZE / 2, 1 + offset)] = source * 10.0f;
                v[IX(SIZE / 2, (SIZE + 1) - offset)] = source * -10.0f;
            }
        }
        #else
            u[IX(SIZE / 2, SIZE / 2)] = force * 10.0f;
            v[IX(SIZE / 2, SIZE / 2)] = force * -10.0f;
        #endif
    }
    if (max_density < 1.0f) {
        #ifdef PROP_SOURCES
        unsigned int offset = 5;
        for (unsigned int count = 0; count < total - 1 && offset < SIZE / 2; count++, offset += sources) {
            if (!(count % 2)) {
                d[IX(1 + offset, 1 + offset)] = source * 10.0f;
                d[IX((SIZE + 1) - offset, (SIZE + 1) - offset)] = source * 10.0f;
                d[IX((SIZE + 1) - offset, 1 + offset)] = source * 10.0f;
                d[IX(1 + offset, (SIZE + 1) - offset)] = source * 10.0f;
            } else {
                d[IX(1 + offset, SIZE / 2)] = source * 10.0f;
                d[IX((SIZE + 1) - offset, SIZE / 2)] = source * 10.0f;
                d[IX(SIZE / 2, 1 + offset)] = source * 10.0f;
                d[IX(SIZE / 2, (SIZE + 1) - offset)] = source * 10.0f;
            }
        }
        #else
            d[IX(SIZE / 2, SIZE / 2)] = source * 10.0f;
        #endif
    }
    
    if (!mouse_down[0] && !mouse_down[2]) {
        return;
    }

    i = (int)((mx / (float)win_x) * SIZE + 1);
    j = (int)(((win_y - my) / (float)win_y) * SIZE + 1);

    if (i < 1 || i > SIZE || j < 1 || j > SIZE) {
        return;
    }

    if (mouse_down[0]) {
        u[IX(i, j)] = force * (mx - omx);
        v[IX(i, j)] = force * (omy - my);
    }

    if (mouse_down[2]) {
        d[IX(i, j)] = source;
    }

    omx = mx;
    omy = my;

    return;
}

/*
  ----------------------------------------------------------------------
   GLUT callback routines
  ----------------------------------------------------------------------
*/

static void key_func(unsigned char key, int x, int y)
{
    switch (key) {
    case 'c':
    case 'C':
        clear_data();
        break;

    case 'q':
    case 'Q':
        free_data();
        exit(0);
        break;

    case 'v':
    case 'V':
        dvel = !dvel;
        break;
    }
}

static void mouse_func(int button, int state, int x, int y)
{
    omx = mx = x;
    omx = my = y;

    mouse_down[button] = state == GLUT_DOWN;
}

static void motion_func(int x, int y)
{
    mx = x;
    my = y;
}

static void reshape_func(int width, int height)
{
    glutSetWindow(win_id);
    glutReshapeWindow(width, height);

    win_x = width;
    win_y = height;
}

static void idle_func(void)
{
    static int times = 1;
    static double start_t = 0.0;
    static double one_second = 0.0;
    static double react_ns_p_cell = 0.0;
    static double vel_ns_p_cell = 0.0;
    static double dens_ns_p_cell = 0.0;

    start_t = wtime();
    react(dens_prev, u_prev, v_prev);
    react_ns_p_cell += 1.0e9 * (wtime() - start_t) / (SIZE * SIZE);

    start_t = wtime();
    vel_step(SIZE, u, v, u_prev, v_prev, visc, dt);
    vel_ns_p_cell += 1.0e9 * (wtime() - start_t) / (SIZE * SIZE);

    start_t = wtime();
    dens_step(SIZE, dens, dens_prev, u, v, diff, dt);
    dens_ns_p_cell += 1.0e9 * (wtime() - start_t) / (SIZE * SIZE);

    if (1.0 < wtime() - one_second) { /* at least 1s between stats */
        printf("%lf, %lf, %lf, %lf: ns per cell total, react, vel_step, dens_step\n",
               (react_ns_p_cell + vel_ns_p_cell + dens_ns_p_cell) / times,
               react_ns_p_cell / times, vel_ns_p_cell / times, dens_ns_p_cell / times);
        one_second = wtime();
        react_ns_p_cell = 0.0;
        vel_ns_p_cell = 0.0;
        dens_ns_p_cell = 0.0;
        times = 1;
    } else {
        times++;
    }

    glutSetWindow(win_id);
    glutPostRedisplay();
}

static void display_func(void)
{
    pre_display();

    if (dvel) {
        draw_velocity();
    } else {
        draw_density();
    }

    post_display();
}


/*
  ----------------------------------------------------------------------
   open_glut_window --- open a glut compatible window and set callbacks
  ----------------------------------------------------------------------
*/

static void open_glut_window(void)
{
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);

    glutInitWindowPosition(0, 0);
    glutInitWindowSize(win_x, win_y);
    win_id = glutCreateWindow("Alias | wavefront");

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();

    pre_display();

    glutKeyboardFunc(key_func);
    glutMouseFunc(mouse_func);
    glutMotionFunc(motion_func);
    glutReshapeFunc(reshape_func);
    glutIdleFunc(idle_func);
    glutDisplayFunc(display_func);
}


/*
  ----------------------------------------------------------------------
   main --- main routine
  ----------------------------------------------------------------------
*/

int main(int argc, char** argv)
{
    glutInit(&argc, argv);
    if (argc != 1 && argc != 7) {
        fprintf(stderr, "usage : %s SIZE dt diff visc force source\n", argv[0]);
        fprintf(stderr, "where:\n");
        fprintf(stderr, "\t SIZE      : grid resolution\n");
        fprintf(stderr, "\t dt     : time step\n");
        fprintf(stderr, "\t diff   : diffusion rate of the density\n");
        fprintf(stderr, "\t visc   : viscosity of the fluid\n");
        fprintf(stderr, "\t force  : scales the mouse movement that generate a force\n");
        fprintf(stderr, "\t source : amount of density that will be deposited\n");
        exit(1);
    }

    if (argc == 1) {
        // SIZE = 100;
        dt = 0.1f;
        diff = 0.0f;
        visc = 0.0f;
        force = 5.0f;
        source = 100.0f;
        fprintf(stderr, "Using defaults : SIZE=%d dt=%g diff=%g visc=%g force = %g source=%g\n",
                SIZE, dt, diff, visc, force, source);
    } else {
        // SIZE = atoi(argv[1]);
        dt = atof(argv[2]);
        diff = atof(argv[3]);
        visc = atof(argv[4]);
        force = atof(argv[5]);
        source = atof(argv[6]);
    }

    printf("\n\nHow to use this demo:\n\n");
    printf("\t Add densities with the right mouse button\n");
    printf("\t Add velocities with the left mouse button and dragging the mouse\n");
    printf("\t Toggle density/velocity display with the 'v' key\n");
    printf("\t Clear the simulation by pressing the 'c' key\n");
    printf("\t Quit by pressing the 'q' key\n");

    dvel = 0;

    if (!allocate_data()) {
        exit(1);
    }

    win_x = 512;
    win_y = 512;
    open_glut_window();

    glutMainLoop();

    exit(0);
}
