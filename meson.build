project('navier_stokes', 'cuda', default_options: [ 'warning_level=1' ])

cc = meson.get_compiler('c')

# llikwid_dep = cc.find_library('likwid', required: true)

# hdf5 = dependency('hdf5', language: 'c')

headless = executable('headless', ['headless.cu', 'solver.cu'])
# , objects: 'lin_solve_ispc'

gl_dep = cc.find_library('GL', required: false)
glu_dep = cc.find_library('GLU', required: false)
glut_dep = cc.find_library('glut', required: false)

 demo = executable('demo', ['demo.cu', 'solver.cu', 'solver.h'], dependencies: [gl_dep, glu_dep, glut_dep])
