����0�  + ���i���O�  + � L� �p�  + � L� �	L� CPM-65 CPU TYPE TESTER V1.00
 
**** CPU is NMOS - 6502 ****
 
**** CPU is CMOS - 65C02 ****
 JSR PUTOPC
	JSR I2CDPCCHR                             $0006  
CP_END                           $0004  CP_BEG