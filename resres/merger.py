from json import load, dumps


def main():
    targets = [
    'T_CUDA_B128_RB_32',
    'T_CUDA_B256_RB_32',
    'T_CUDA_B512_RB_32',
    'T_CUDA_B1024_RB_32',
    'T_CUDA_B128_RB_16',
    'T_CUDA_B256_RB_16',
    'T_CUDA_B512_RB_16',
    'T_CUDA_B1024_RB_16'
    ]

    res = []
    for t in targets:
        filenames = [
            f'summ{t}.json',
            f'summ{t}_S1024.json',
            f'summ{t}_S2048.json',
            f'summ{t}_S4096.json'
        ]
        
        fbase = open(filenames[0], mode='r')
        base = load(fbase)
        fbase.close()
        a = {}
        
        for f in filenames[1:]:
            fnew = open(f)
            new = load(fnew)
            fnew.close()
            key = list(new[t].keys())[0]
            base[t][key] = new[t][key]
        res.append(base)
    fres = open('merge_res.json', 'x')
    fres.write(dumps(res))
    fres.close()

if __name__ == '__main__':
    main()