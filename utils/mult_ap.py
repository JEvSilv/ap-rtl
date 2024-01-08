# Class representing the associative multiplication
class MultAp:
    def __init__(self, a, b, bit_size):
        self.a = a
        self.b = b
        self.bit_size = bit_size
        self.c = 0

        #                 {     Compare    ||  Write }
        #                 { Cr | R | B | A || Cr | R }
        self.lut_mult = [ ( 0,   1,  1,  1,   1,   0),
                          ( 0,   0,  1,  1,   0,   1),
                          ( 1,   0,  0,  1,   0,   1),
                          ( 1,   1,  0,  1,   1,   0) 
                        ]

        self.mask_a = 0
        self.mask_b = 0
        self.mask_c = 0

        self.key_a  = 0
        self.key_b  = 0
        self.key_c  = 0

    def monitor(self, _pass=0):
        print("#----- @Monitor ----#")
        print("pass:", _pass)
        print(" Compare   |  Write ")
        print("Cr, R, B, A| Cr, R ")
        print(self.lut_mult[_pass], "\n")

        print("A: ",  self.a, 
              "B: ",  self.b, 
              "BS: ", self.bit_size)

        print("mask_a: \t", bin(self.mask_a).split('b')[1])
        print("mask_b: \t", bin(self.mask_b).split('b')[1])
        print("mask_c: \t", bin(self.mask_c).split('b')[1])
        print("key_a: \t\t", bin(self.key_a).split('b')[1])
        print("key_b: \t\t", bin(self.key_b).split('b')[1])
        print("key_c: \t\t", bin(self.key_c).split('b')[1])
        print("C:\t\t", bin(self.c).split('b')[1])


    def reset(self):
        self.mask_a = 0
        self.mask_b = 0
        self.mask_c = 0
        self.key_a  = 0
        self.key_b  = 0
        self.key_c  = 0
        c = 0

    def set_bit(self, data, bit, value):
        return (data & ~(1 << bit)) | (value << bit)

    def bit_check(self, data, bit):
        return (data >> bit) & 1

    def set_mask(self, bit_a, bit_b, rk, cr_k):
        self.mask_a = self.mask_b = self.mask_c = 0
        self.mask_c = self.set_bit(self.mask_c, rk,    1)
        self.mask_c = self.set_bit(self.mask_c, cr_k,  1)
        self.mask_a = self.set_bit(self.mask_a, bit_a, 1)
        self.mask_b = self.set_bit(self.mask_b, bit_b, 1)

    def set_key(self, _pass, bit_a, bit_b, rk, cr_k):
        self.key_a = self.key_b = self.key_c = 0
        self.key_c = self.set_bit(self.key_c, cr_k,  self.lut_mult[_pass][0])
        self.key_c = self.set_bit(self.key_c, rk,    self.lut_mult[_pass][1])
        self.key_a = self.set_bit(self.key_a, bit_a, self.lut_mult[_pass][3])
        self.key_b = self.set_bit(self.key_b, bit_b, self.lut_mult[_pass][2])

    def compare_and_write(self, _pass, bit_a, bit_b, rk, cr_k):
        masked_a = self.a & self.mask_a
        masked_b = self.b & self.mask_b
        masked_c = self.c & self.mask_c
        
        # Match comparison
        if(masked_a == self.key_a 
                and masked_b == self.key_b 
                and masked_c == self.key_c):
            print("@Match!")
            print("{","rk:", rk, "  w:", self.lut_mult[_pass][5], "}")
            print("{","cr_k:", cr_k, "w:", self.lut_mult[_pass][4], "}")

            self.c = self.set_bit(self.c, rk, self.lut_mult[_pass][5])
            self.c = self.set_bit(self.c, cr_k, self.lut_mult[_pass][4])

    def mult_ap(self):
        cycles = 0
        self.reset()
        for bit_a in range(self.bit_size):
            for bit_b in range(self.bit_size):
                for _pass in range(len(self.lut_mult)):
                    rk   = bit_a    + bit_b
                    cr_k = self.bit_size + bit_a

                    self.set_mask(bit_a,bit_b, rk, cr_k)
                    self.set_key(_pass, bit_a, bit_b, rk, cr_k)
                    self.compare_and_write(_pass, bit_a, bit_b, rk, cr_k)
                    self.monitor(_pass)
                    # 1 cycle for comparison and 1 cycle for write
                    cycles = cycles + 2
        print("BS:", self.bit_size, "C:", self.c, " | ", "cycles:", cycles)
    
bits = [2,3,4,5,6,7,8]

b = 9 
a = 9
ma = MultAp(a, b, 4)
# ma.monitor()
ma.mult_ap()
