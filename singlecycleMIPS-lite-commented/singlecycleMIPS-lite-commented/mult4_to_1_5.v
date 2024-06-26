module mult4_to_1_5(out, i0, i1, i2, i3, s0, s1);
    output [4:0] out;
    input [4:0] i0, i1, i2, i3;
    input s0, s1;

    assign out = (s1 == 0 && s0 == 0) ? i0 :
                 (s1 == 0 && s0 == 1) ? i1 :
                 (s1 == 1 && s0 == 0) ? i2 :
                                        i3;
endmodule
