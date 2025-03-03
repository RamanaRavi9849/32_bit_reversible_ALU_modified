`timescale 1ns / 1ps



module ALU_reversible_logicgates(
    input [31:0] A, B,         
    input [2:0] sel,           
    input Cin,                 
    output [31:0] F,         
    output Cout
);
    wire [31:0] carry;           
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: alu_bits
            one_bit_reversible_alu ALU (
                .A(A[i]),
                .B(B[i]),
                .Cin((i == 0) ? Cin : carry[i-1]),
                .sel(sel),
                .out(F[i]),
                .cout(carry[i])
            );
        end
    endgenerate
    assign Cout = carry[31];

endmodule

module feynman_gate(
    input A, 
    output P, Q
);
    assign P = A;  
    assign Q = A ^1'b1;  
endmodule


module toffoli_gate(
    input A, B, C, 
    output P, Q, R
);
    assign P = A;
    assign Q = B;
    assign R = C ^ (A & B);  
endmodule


module peres_gate(
    input A, B, Cin, 
    output P, Q, R
);
    assign P = A;
    assign Q = A ^ B;     
    assign R = (A & B) ^ Cin; 
endmodule

module fredkin_gate(
    input S, A, B, 
    output P, Q, R
);
    assign P = A;  
    assign Q = S ? B : A;  
    assign R = S ? A : B;  
endmodule


module one_bit_reversible_alu(
    input A, B, Cin, 
    input [2:0] sel, 
    output out, 
    output cout
);
    wire and_operation, or_operation, xor_operation, add_operation, sub_operation, left_shift, right_shift;
    wire peres_p, peres_q, peres_r;
    
    // Logic Operations using Reversible Gates
    toffoli_gate toff1(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(and_operation));  
    toffoli_gate toff2(.A(A), .B(1'b1), .C(B), .P(), .Q(), .R(or_operation));   
    toffoli_gate toff3(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(xor_operation));  

    // Addition using Peres Gate
    peres_gate peres1(.A(A), .B(B), .Cin(Cin), .P(peres_p), .Q(peres_q), .R(peres_r));
    assign add_operation = peres_q;
    assign cout = peres_r;

    // Subtraction using 2's Complement (A - B = A + NOT(B) + 1)
    wire notB;
    feynman_gate feyn1(.A(B), .P(), .Q(notB));
    peres_gate peres2(.A(A), .B(notB), .Cin(Cin), .P(), .Q(sub_operation), .R());

    // Shift operations using Fredkin Gate
    fredkin_gate fred1(.S(sel[0]), .A(A), .B(B), .P(), .Q(left_shift), .R(right_shift));

    // Multiplexer for ALU Operation Selection
    assign out = (sel == 3'b000) ? and_operation : 
                 (sel == 3'b001) ? or_operation  :
                 (sel == 3'b010) ? xor_operation :
                 (sel == 3'b011) ? add_operation :
                 (sel == 3'b100) ? sub_operation :
                 (sel == 3'b101) ? left_shift :
                 (sel == 3'b110) ? right_shift : 
                 1'b0;
endmodule


