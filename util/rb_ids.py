def id(x,n):
    # negros
    rojo = x < (n*n / 2)
    if rojo:
        i = int(x * 2/n)
        ipar = i % 2 != 0
        j = int((x % (n/2) * 2) + ipar)
        print(i,j)
    else:
        idx_n = (x - (n*n/ 2))
        i = int(idx_n * 2/n)
        ipar = i % 2 == 0
        j = int((idx_n % (n/2) * 2) + ipar)
        print(i,j)

if __name__ == '__main__':
    id(32, 64)
    id(2048,64)
    id(2112,64)
    id(2080,64)
    id(2081,64)