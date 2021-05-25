project('navier_stokes', 'c', default_options: [ 'warning_level=2' ])

cc = meson.get_compiler('c')

# llikwid_dep = cc.find_library('likwid', required: true)

# hdf5 = dependency('hdf5', language: 'c')

headless = executable('headless',
    [ 'headless.c', 'solver.c'], objects: 'lin_solve_ispc')

gl_dep = cc.find_library('GL', required: false)
glu_dep = cc.find_library('GLU', required: false)
glut_dep = cc.find_library('glut', required: false)

 demo = executable('demo', ['demo.c', 'solver.c', 'solver.h'], objects: ['lin_solve_ispc'],
       dependencies: [gl_dep, glu_dep, glut_dep])
