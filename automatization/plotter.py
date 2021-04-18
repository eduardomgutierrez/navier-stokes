import numpy as np
import matplotlib.pyplot as plt
import functools as fn
import matplotlib
import json
import getopt
import sys

from run import SIZES
# SIZES = [256,512,1024,2048]


def plot(path: str):
    with open(path) as f:
        all_runs = json.load(f)
        flags = list(all_runs.keys())

        react_avg = []
        dens_avg = []
        vel_avg = []
        total_avg = []
        react_time_avg = []
        dens_time_avg = []
        vel_time_avg = []
        total_time_avg = []

        flags_per_size = []
        for f in flags:
            for s in SIZES:
                flags_per_size.append((f, s))
        # print(flags_per_size)

        for flag in flags_per_size:
            f, s = flag
            s = str(s)

            print(all_runs[f][s])
            react_Runtime = np.zeros_like(all_runs[f][s])
            dens_Runtime = np.zeros_like(all_runs[f][s])
            vel_Runtime = np.zeros_like(all_runs[f][s])
            total_Runtime = np.zeros_like(all_runs[f][s])
            react_Mflops = np.zeros_like(all_runs[f][s])
            dens_Mflops = np.zeros_like(all_runs[f][s])
            vel_Mflops = np.zeros_like(all_runs[f][s])
            total_Mflops = np.zeros_like(all_runs[f][s])
            # return
            i = 0
            for run in all_runs[f][s]:
                react_Runtime[i] = np.float32(
                    run['REACT']['Runtime (RDTSC) [s]'])
                dens_Runtime[i] = np.float32(
                    run['DENS']['Runtime (RDTSC) [s]'])
                vel_Runtime[i] = np.float32(run['VEL']['Runtime (RDTSC) [s]'])
                total_Runtime[i] = np.float32(
                    run['TOTAL']['Runtime (RDTSC) [s]'])
                react_Mflops[i] = np.float32(run['REACT']['SP [MFLOP/s]'])
                dens_Mflops[i] = np.float32(run['DENS']['SP [MFLOP/s]'])
                vel_Mflops[i] = np.float32(run['VEL']['SP [MFLOP/s]'])
                total_Mflops[i] = np.float32(run['TOTAL']['SP [MFLOP/s]'])
                i += 1
            react_time_avg.append(
                [np.average(react_Runtime), np.std(react_Runtime)])
            dens_time_avg.append(
                [np.average(dens_Runtime), np.std(dens_Runtime)])
            vel_time_avg.append([np.average(vel_Runtime), np.std(vel_Runtime)])
            total_time_avg.append(
                [np.average(total_Runtime), np.std(total_Runtime)])
            react_avg.append([np.average(react_Mflops), np.std(react_Mflops)])
            dens_avg.append([np.average(dens_Mflops), np.std(dens_Mflops)])
            vel_avg.append([np.average(vel_Mflops), np.std(vel_Mflops)])
            total_avg.append([np.average(total_Mflops), np.std(total_Mflops)])

        react_time_avg = np.array(react_time_avg)
        dens_time_avg = np.array(dens_time_avg)
        vel_time_avg = np.array(vel_time_avg)
        total_time_avg = np.array(total_time_avg)
        react_avg = np.array(react_avg)
        dens_avg = np.array(dens_avg)
        vel_avg = np.array(vel_avg)
        total_avg = np.array(total_avg)

        ms = 10
        elw = 3
        cs = 6
        ct = 3

        fig, ax1 = plt.subplots(figsize=(14, 7))
        x_array = np.arange(1, np.size(total_avg[:, 0]) + 1)

        ax1.set_title('Total', fontsize=30)
        ax1.set_ylabel('SP [GFLOP/s]', fontsize=25)
        ax1.set_xticks(ticks=x_array)
        ax1.tick_params(axis='both', labelsize=20)
        ax1.tick_params(axis='both', which='major', length=10, width=2, pad=8)

        ax1.set_xticklabels(
            list(map(lambda x: x[0]+f'_{x[1]}', flags_per_size)), rotation=90)

        total_avg_vec = total_avg[:, 0]
        total_std_vec = total_avg[:, 1]
        ax1.errorbar(x_array, total_avg_vec * 1e-3, total_std_vec * 1e-3, lw=2, marker='o', markersize=ms, elinewidth=elw,
                    capsize=cs, capthick=ct, label='Total', color='tab:blue')
                    
        ax1.grid(ls='--', alpha=0.5)
        # ax1.legend(fontsize=22)

        plt.tight_layout()
        fig.savefig("total.pdf")
        fig.savefig("total.jpg")


def usage():
    print('Plotter usage:')


def main():
    try:
        opts, args = getopt.getopt(
            sys.argv[1:], "hp:", ["help", "output="])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)

    path = None

    for o, a in opts:
        if o == '-p':
            path = a

    if(path is None):
        print('@ Error, argument -p PATH is required.')
        return

    plot(path)

if __name__ == '__main__':
    main()
   
