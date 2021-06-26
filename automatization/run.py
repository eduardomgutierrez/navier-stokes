import sys
import getopt
from functools import reduce
from json import load, dumps, JSONDecodeError
from target import Target
from subprocess import run
from os import path as ph, chdir as ch, environ, write
import numpy as np


""" Run variables """
CORE = 1                # Selected core[s] to run the likwid-perfctr.
COLLECT = False         # Collect perf data.

# 
RT = 1

# GFLOPs, IPC, CellsXTime
# SIZES = [66,  258, 512]
SIZES = [256,512,1024]

""" Counter groups, and collect metadata """
FL_SP = ('FLOPS_SP', ['Runtime (RDTSC) [s]',
                      'SP [MFLOP/s]', 'IPC'])

BR = ('BRANCH', ['Branch rate',
                 'Branch misprediction rate',
                 'Branch misprediction ratio',
                 'Instructions per branch'])

L2 = ('L2CACHE', ['L2 request rate',
                  'L2 miss rate',
                  'L2 miss ratio'])

JUSTCOMPILE = False

# Agregar GCC a los targets.

""" Defined targets """
targets = [
    Target(name='T_OMP', flags=['-O2', '-march=native', '-funroll-loops', '-ffast-math', '-DRB', '-DPAR_LINSOLVE', '-fopenmp'],),
    # Target(name='T_OMP_C', comp = 'clang-9', flags=['-O2', '-march=native', '-funroll-loops', '-ffast-math', '-DRB', '-DPAR_LINSOLVE', '-fopenmp'],)

    Target(name='T_CUDA_B128_RB_32', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B256_RB_32', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B512_RB_32', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B1024_RB_32', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),

    Target(name='T_CUDA_B128_RB_16', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B256_RB_16', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B512_RB_16', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],),
    Target(name='T_CUDA_B1024_RB_16', comp='clang-6.0', flags=['-O2', '-Xcompiler=-Wall', '-arch=sm_75', '-DBLOCK_SIZE=256'],)
    
]

""" Directory handlers """
def fw(n): return ch(ph.join(ph.curdir, n))
def bw(): return ch('../')


def runner(t: Target, run_file, log_file):
    # Get env
    env = dict(environ)

    for ev in t.evars:
        env[ev[0]] = ev[1]

    fw(t.name)

    stats_file = open(
        'stats.json', mode='w' if ph.isfile('stats.json') else 'x')

    compile_res = run(['meson', 'compile'], shell=False,
                      capture_output=True, env=env)

    run_file.write(compile_res.stdout.decode('utf-8'))

    if(JUSTCOMPILE):
        bw()
        return

    if(compile_res.returncode == 0):

        run_res = None
        if(t.stats_collectors is not None and COLLECT):
            res = []
            for i in range(RT):
                # outputs = []
                # output = ''
                collected = []
                for sc in t.stats_collectors:
                    print(f'@ Compiled {t.name}\n@ Running ./headless i = {i}')
                    run_res = run(['likwid-perfctr', '-C', f'{CORE}', '-g', sc[0], '-m', '-O',
                                  './headless'], shell=False, capture_output=True, env=env)
                    if(run_res.returncode == 0):
                        collected.append(collect1(sc, run_res.stdout.decode(
                            'ascii'), stats_file, log_file, t.flags))
                    else:
                        return f'@! Error running {t.name}/headless (likwid-perf)'
                res.append(merge_collected(collected))
            stats_file.write(dumps(res))
            bw()
            print(f'@ Collected performance stats: {t.name}/stats')
            return res

        else:
            res = []
            for i in range(RT):
                run_res = run('./headless', shell=False,
                              capture_output=True, env=env)
                if(run_res.returncode == 0):
                    res.append(collect1(None, run_res.stdout.decode(
                        'ascii'), stats_file, log_file, t.flags))
                else:
                    return f'@! Error running {t.name}/headless'
            stats_file.write(dumps(res))
            bw()
            return res

    else:
        bw()
        print(compile_res.stdout)
        log_file.write(compile_res.stdout.decode('ascii'))
        return f'@! Error compiling{t.name}. See run.log for more details.'


def merge_collected(collected: list):
    res = collected[0]
    if(len(collected) == 0):
        raise Exception('Errr1')

    for c in collected[1:]:
        for k in c.keys():
            res[k].update(c[k])

    return res


def collect(sc, outputs, stats_file, log_file, flags):
    print(f'@ Collecting data for group: {sc[0]}')
    res = []
    for output in outputs:
        try:
            lines = output.splitlines(keepends=False)

            regions_ids = []

            for id in range(0, len(lines)):
                line = lines[id]
                if(line.startswith('TABLE') and any(map(lambda x: 'Metric' in x, line.split(',')))):
                    regions_ids.append(id)

            stats = {}
            for id in regions_ids:
                region_name = lines[id].split(',')[1].split(' ')[1]
                r_id = 1
                region_line = lines[id+r_id].split(',')
                stats[region_name] = {}
                while(region_line[0] != 'TABLE' and id+r_id < len(lines) - 1):
                    if(region_line[0] in sc[1]):
                        region_stats = stats[region_name]
                        region_stats[region_line[0]] = region_line[1]
                    r_id += 1
                    region_line = lines[id+r_id].split(',')
            res.append(stats)
        except Exception as err:
            log_file.write(str(err))
            return '@! Error collecting data. See run.log for more details.'

    stats_file.write(dumps({'flags': flags, 'res': res}))
    return None


def collect1(sc, output, stats_file, log_file, flags):
    
    # print(f'@ Collecting data for group: {sc[0]}')
    try:
        lines = output.splitlines(keepends=False)
        regions_ids = []

        for id in range(0, len(lines)):
            line = lines[id]
            if(line.startswith('TABLE') and any(map(lambda x: 'Metric' in x, line.split(',')))):
                regions_ids.append(id)
        
        stats = {}

        if(list(filter(lambda x: x.startswith("# CELL_MS"), lines)) != []):
            line = next(x for x in lines if x.startswith("# CELL_MS"))
            stats['CELL_MS'] = float(line.split(':')[1])

        if(sc is not None):
            for id in regions_ids:
                region_name = lines[id].split(',')[1].split(' ')[1]
                r_id = 1
                region_line = lines[id+r_id].split(',')
                stats[region_name] = {}
                while(region_line[0] != 'TABLE' and id+r_id < len(lines) - 1):
                    if(region_line[0] in sc[1]):
                        region_stats = stats[region_name]
                        region_stats[region_line[0]] = region_line[1]
                    r_id += 1
                    region_line = lines[id+r_id].split(',')
        return stats
    except Exception as err:
        log_file.write(str(err))
        return '@! Error collecting data. See run.log for more details.'


def configure(t, log_file, run_size):
    cmd = ['meson', 'setup', f'{t.name}']
    wipe_cmd = ['meson', 'setup', '--wipe']

    # Get env
    env = dict(environ)

    # Set compiler.
    if t.comp is not None:
        env['CC'] = t.comp

    t.flags.append(f'-DN={run_size}')

    if(t.stats_collectors is not None):
        t.flags.append('-DLIKWID_PERFMON')

    env['CUFLAGS'] = ' '.join(t.flags)

    if(ph.isdir(ph.join(ph.curdir, t.name))):
        print(f'@ Target {t.name} already exists, reconfiguring with run size: {run_size}.')

        fw(t.name)

        res = run(wipe_cmd, shell=False, capture_output=True, env=env)
        log_file.write(res.stdout.decode('ascii'))

        bw()

        if(res.returncode != 0):
            return f'@! Error reconfiguring {t.name}. See run.log for more details.'

        print('@ Reconfigured succesfully.')

    else:
        print(f'@ Creating target {t.name}, with run size: {run_size}')
        res = run(cmd, shell=False, capture_output=True, env=env)
        log_file.write(res.stdout.decode('ascii'))
        if(res.returncode != 0):
            return f'@! Error creating {t.name}. See run.log for more details.'

        print('@ Target created succesfully.')


def automatize(tgs):
    log_file = open('run.log', mode='w' if ph.isfile('run.log') else 'x')
    res = {}
    for tg in tgs:
        run_file = open(f'run_{tg.name}.out','a' if ph.isfile(f'run_{tg.name}.out') else 'x')
    
        if(JUSTCOMPILE):
            conf = configure(tg, log_file, 1024)
            if(conf is not None):
                    print(conf)
                    return
            runner(tg,run_file, log_file)
        else: 
            sizes = {}
            for n_size in SIZES:
                conf = configure(tg, log_file, n_size)
                if(conf is not None):
                    print(conf)
                    return
                runn = runner(tg,run_file, log_file)
                sizes[str(n_size)] = runn
            res[tg.name] = sizes

        run_file.close()

    env = dict(environ)
    if ('OMP_NUM_THREADS' in env.keys() is not None):
        tn = env['OMP_NUM_THREADS']

        if(len(SIZES) == 1):
            summ = open(f'summ{tg.name}_TN{str(tn)}_S{str(SIZES[0])}.json', mode='w' if ph.isfile(f'summ{tg.name}_TN{str(tn)}_S{str(SIZES[0])}.json') else 'x')
            summ.write(dumps(res))
        else:
            summ = open(f'summ{tg.name}_TN{str(tn)}.json', mode='w' if ph.isfile(f'summ{tg.name}_TN{str(tn)}.json') else 'x')
            summ.write(dumps(res))
    else:
        if(len(SIZES) == 1):
            summ = open(f'summ{tg.name}_S{str(SIZES[0])}.json', mode='w' if ph.isfile(f'summ{tg.name}_S{str(SIZES[0])}.json') else 'x')
            summ.write(dumps(res))
        else:
            summ = open(f'summ{tg.name}.json', mode='w' if ph.isfile(f'summ{tg.name}.json') else 'x')
            summ.write(dumps(res))

def usage():
    """ Prints command usage. """
    print('Navier-Stokes automatization helper.')
    print('List of avaiable options:')
    print('-t TARGETNAME                  Automatize specific target.')
    print('-c CORE | CORE1 - COREN        Set cores to run performance counters.')
    print('-d                             Enable performance counters and collect data.')
    print('-s                             Generate summary from collected data.')

def clean():

    if(run('rm T_* -r', shell=True).returncode == 0):
        return '@ Build directories cleaned succesfully.'
    else:
        return '@ Error while cleaning directories.'

def summary(targets: list):

    summary_file = open('sum.json', mode='w' if ph.isfile('sum.json') else 'x')

    output = {}

    for t in targets:
        if(not ph.isdir(t.name)):
            continue

        fw(t.name)
        s = open('stats.json', mode='r')
        try:
            sum = load(s)
            output[t.name] = sum
        except JSONDecodeError:
            output[t.name] = ''
        bw()
    summary_file.write(dumps(output))


def main():
    """ Main """
    try:
        opts, args = getopt.getopt(
            sys.argv[1:], "jhsCdc:t:r:S:", ["help", "output="])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)

    target = None
    clean_dirs = False
    s = False

    for o, a in opts:
        if o == '-c':
            global CORE
            CORE = a
        if o == '-t':
            if(a not in list(map(lambda x: x.name, targets))):
                print('Target not defined.')
                return
            target = [next((x for x in targets if x.name == a), None)]
        if o == '-d':
            global COLLECT
            COLLECT = True

        if o == '-C':
            clean_dirs = True

        if o == '-s':
            """ Summary """
            s = True

        if o == '-r':
            """ Runtimes """
            global RT
            RT = int(a)

        if o == '-j':
            """ Just compile """
            global JUSTCOMPILE
            JUSTCOMPILE = True
        
        if o == '-S':
            """ Set size """
            global SIZES
            SIZES = [a]

        elif o == '-h':
            usage()
            return

    if(s):
        summary(targets)
        return

    if(clean_dirs):
        print(clean())
        return

    automatize(targets if target is None else target)


if __name__ == '__main__':
    main()
