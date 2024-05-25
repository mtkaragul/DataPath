module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4, 		//Output of mux with (Branch&ALUZero) control-mult4
out4_1, 		//Output of mux with (Branch&ALUZero) control-mult4
sum,		//ALU result
extad,		//Output of sign-extend unit
zextad,		//Output of zero-extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad;	//Output of shift left 2 unit

wire [5:0] inst31_26, inst5_0;	//Opcode
wire [4:0] 
inst25_21,	//RS
inst20_16,	//RT
inst15_11,	//RD
out1_1,     //first mux regdest and jmxorControl or balnControl
out1;		//Write data input of Register File

wire [15:0] inst15_0;	//15-0 bits of instruction LABEL
wire [25:0] inst25_0;	//25-0 bits of instruction LABEL
wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [3:0] gout;	//Output of ALU control unit

wire [25:0] j_type_address; //J type address

wire zout,	//Zero output of ALU

//Control signals
regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop2,aluop1,aluop0,
noriControl, blezalControl, balnControl, jalpcControl, brvControl, jmxorControl; // new instruction controls

reg statusN, statusV, statusZ;	//Status bits
// jmxorControl or balnControl
wire jmxorcORbalnc;
assign jmxorcORbalnc = jmxorControl || balnControl;

//jmxorrControl or blezalControl or jalpcControl
wire jmxorcORblezalORjalpcORbaln;
assign jmxorcORblezalORjalpcORbaln = jmxorControl || blezalControl || jalpcControl || balnControl;

//statusz or statusn
wire statuszORstatusn;
assign statuszORstatusn = statusZ || statusN;

//blezalControl and statuszORstatusn
wire blezalANDstatuszORstatusn;
assign blezalANDstatuszORstatusn = blezalControl && statuszORstatusn;

//statusV and brvControl
wire statusvANDbrv;
assign statusvANDbrv = statusV && brvControl;

//jmxor or statusvANDbrv
wire pcsrc1;
assign pcsrc1= jmxorControl || statusvANDbrv;

//branch and zout
wire branchANDzout;
assign branchANDzout=branch && zout; 

//branchandzout or jalpcControl or blezalANDstatuszORstatusn
wire pcsrc0;
assign pcsrc0 = branchANDzout || jalpcControl || blezalANDstatuszORstatusn;

//statusn and balnControl
wire statusnANDbaln;
assign statusnANDbaln = statusN && balnControl; 


//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];
//32 adet 32 bit register tanımlanıyor burada 


integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[sum[4:0]+3]=datab[7:0];
datmem[sum[4:0]+2]=datab[15:8];
datmem[sum[4:0]+1]=datab[23:16];
datmem[sum[4:0]]=datab[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]}; // yani instuction memoryden 4 tane hexadesimal alıyorum
 assign inst31_26=instruc[31:26]; 
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];
 assign inst5_0=instruc[5:0];
 assign inst25_0=instruc[25:0];


// Baln operation
//
// 	(PC+4) [31:28] + Label [27:2] + [00]
//

wire [3:0] first4BitsOfPC;
wire [31:0] pseudoAddress;
wire [27:0] extendedLabelAddress;

assign first4BitsOfPC = adder1out[31:28];
assign extendedLabelAddress = {inst25_0, 2'b00}; //shift left 2
assign pseudoAddress = {first4BitsOfPC,extendedLabelAddress}; 	//pcnin ilk 4 biti ile labelin 28 biti concatene ediliyor



// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)
 registerfile[out1]= regwrite ? out3:registerfile[out1];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

/////////////////////////
//multiplexers

//mux with RegDst control and (jmxorControl or balnControl)
wire [4:0] thirtyone;
assign thirtyone=5'b11111;
mult4_to_1_5  mult1(out1_1, inst20_16,inst15_11,thirtyone,thirtyone,regdest,jmxorcORbalnc);

//mux blezalControl 
wire [4:0] twentyfive;
assign twentyfive=5'b11001;
mult2_to_1_5 mult5(out1, out1_1, twentyfive, blezalControl);

//mux with ALUSrc control
mult4_to_1_32 mult2(out2, datab,extad,zextad, zextad, alusrc, noriControl);

//mux with MemToReg control
mult4_to_1_32 mult3(out3, sum,dpack,adder1out,adder1out,memtoreg,jmxorcORblezalORjalpcORbaln); //data pack ve sum yer değiştirdim dpack i0 konumunda çünkü

//mux with (Branch&ALUZero) control
mult4_to_1_32 mult4(out4_1, adder1out,adder2out,sum, sum ,pcsrc0, pcsrc1);

// mux for baln 
mult2_to_1_32 mult6(out4, out4_1, pseudoAddress ,statusnANDbaln); // added LabelAddress

// load pc
always @(negedge clk)
pc=out4;
// alu, adder and control logic connections

wire statusN_t, statusV_t, statusZ_t;
//ALU unit
alu32 alu1(sum,dataa,out2,zout,gout, statusN_t,statusV_t,statusZ_t,clk);

always @(negedge clk)
begin
statusN = statusN_t;
statusV = statusV_t;
statusZ = statusZ_t;
end

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

//Control unit
control cont(inst31_26,inst5_0,regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop0,
aluop1,aluop2,brvControl,jmxorControl,jalpcControl,balnControl,blezalControl,noriControl);

//Sign extend unit
signext sext(inst15_0,extad);
zeroext zext(inst15_0,zextad);

//ALU control unit
alucont acont(aluop2,aluop1,aluop0,instruc[5],instruc[4],instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);



//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDM.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
	
end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial 
begin

  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end
initial
begin
	#400    
    $display("Data Memory Content:");
    for (i = 0; i < 32; i = i + 1) begin
        $display("datmem[%0d] = %h", i, datmem[i]);
    end
    
    $display("Register File Content:");
    for (i = 0; i < 32; i = i + 1) begin
        $display("registerfile[%0d] = %h", i, registerfile[i]);
    end
	$writememh("finalDM.dat",datmem); //write Data Memory
	$writememh("finalReg.dat",registerfile); //write Register File
	$finish;
end
endmodule

