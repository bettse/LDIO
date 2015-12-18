
import struct
from struct import unpack, pack

class BurtleRandom(object):
    def __init__(self, seed):
        self.random_seed = [0xf1ea5eed, int(seed), int(seed), int(seed)]
        for _ in range(42):
            self.value()

    def rot (self, x, k):
        return ((x << k) & 0xffffffff) | (x >> (32 - k))

    def value(self):
        extra = self.random_seed[0] - self.rot(self.random_seed[1], 21)
        self.random_seed[0] = self.random_seed[1] ^ self.rot(self.random_seed[2], 19)
        self.random_seed[1] = (self.random_seed[2] + self.rot(self.random_seed[3], 6)) & 0xffffffff
        self.random_seed[2] = (self.random_seed[3] + extra) & 0xffffffff
        self.random_seed[3] = (extra + self.random_seed[0]) & 0xffffffff
        return self.random_seed[3]

if __name__ == "__main__":
    b = BurtleRandom(0)
    for r in range(1, 6):
        v = b.value()
        #Correct endianness
        packed = pack('I', v)
        unpacked = unpack('>I', packed)[0]

        print("%i: %08x" % (r, unpacked))

