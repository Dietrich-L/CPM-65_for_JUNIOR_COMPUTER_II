 %  c �)�) '�
 � � �  � ��Ʉ�� �&L �����(� �@� ��� ����	�Ѕ��+�� X  �!�` �&�Ң L� � �(�)�*� `���( '��) '��"  ?'���!�) '���( ?'��` � H� � H� � h � h � `� 8�
����i
`	0L' �%�)�;� �%� � ��� ��������ȹ� Hȹ� H`��8`S!L!%D!<C!p+!�-!�R!�W!�I!�M!�P"7X"d?"iZ"q>"�<"�/"�B"�  D%� �!` D%�"&#&$&%� �!`��8` c � � '��� �$Ș)H��� 'h���� %Ș)�����` �%�
�H��A�"��8` S%��� S%�������8`Ɂ��` S%�ۅ �%�Ԥ�����8`� �"����� �!`� �"�"������� �!` �%` &` �"�
 m#���`8` �% �$�/�0�5�* �%�)�,�� S%��5�

�� ��,�1������0� �%`��8`�0	��0�� �#�$�%��"��H��H� ���؅��"� �%� �%h��h��`�  � �8�) '` %���
��N������������`� ������`� ������`��
��� � ` %�
�� �멂8`Ɂ���
��ݩ�8` S%��	�`� ���(��(��(�� v&�^���u�����(��(�� v&�F���(���(���(���(���( �$���(���(���(�(� �$��(�� �$ �!`�$��(�%��(�&��(�'��(L?#��8` C$ y# $��`���.���/�,




e.�.��/� �.���I��.� �A �$�< '�5 ?'�: ' �$ �#��) '�5

����,*H�����h ?'����5�5�@�`��`��.��(ȱ.��(��.��(ȱ.��( {$�5

�� ����(}�(��,�����`�,��-�-��(��,��(��,)� �!�`�`� �,�-��(�5��(��(� �$��� �$���(��(�� {$ �$����(� ��(`��(�J�� �$L~$`�(.�(.�(.�(`� ���(}�(��(��`� ��(*�"����`���.��(����`8`� �. '������. 'L�$`��@�)��`� `��8` ?'�  '`)� ����. '` S%�')�
��	�
)�JHe	�	hJJe	���0id����8`�	` S%�	��
�"��`� ��
��� �%�	��	����8`� �� ��Ʉ��;�쩁8`�;��,�Ʉ�ܥ
�` �%��0��:��A��G�8`i	)�
&&���
�
`� � � ����� �%`��`�a��~�)_`�L�  <&�$ X&� l&��"J� �
� �����`� �����` <&�� X&� l&��"J� �
��� ������� �������(`��" j��(���@�� ���(�`���(��(�����(
`8`,�( �&���(�% ��8`��(�& ������(��(��� ��(`��(�& ����`�! '����'�� ���)�!� '�� 'L�& 'H �& '��� 'h	 ('�!` '8`� J���������p'� '����V�' '�! ?'�5�)�	L� �L� ������`�_�' '� �  �%�Y�`8`HJJJJ J'h)�
�ii0 '` Error $ 
Retry (Y/N) ?  BIOS BDOS CCP  RSX  USER �Invalid Drive ނDirectory full ݂File not found �File exists �Invalid FCB ؂Disk full ւFile is R/O �no image available �too many IMG files �no partition found �no SD card found �SD card changed �SD card write protected �Invalid Drive �End of Line �Too Much Parameters �Illegal Parameter �Missing Parameter �Unknown Command      ����    ����              
SD-UTIL V1.5  SD-Drive :  Sector     LBA  
Command > 
    SD-UTIL V1.5                    (c) 18.7.2023
Command Summary:
 D  dump current sector      Snnnnnn    read sector nnnnnn
 +  read next sector         -  read last sector
 R  read current sector      W  write current sector
 I  read SD directory        Md,m  mount on d image m
 P  push mounted d to disc   Znn        wait for nn/10 s
 >  save sector to buffer    <  get sector from buffer
 Baddr set buffer to addr    /nn        repeat nn times
 CHad,by,by,...     change value at ad with by
 CAad,<string>      change at ad with string
 ?  prints this screen       ;   command separator
 Lnnnnnn  read LBA nnnnnn    X  exit to CP/M            
 SET DMA TO BIOS
	STA DMA
	LDA #BIOSV/256
	STA
 Lnnnnnn  read LBA nnnnnn    X  exit to CP/M            
 10
	STA MCNT 		;100 MS
WAIT2	LDX #78
WAIT1	DEY
	BNE WAIT1
	DEX
	BNE WAIT1
	DEC MCNT
	BNE WAIT2
	DEC CNT
	BNE WAIT3
	CLC
WAITX	RTS


STOBUF	LDY #0			;SAVE DMA TO BUFFER
STOBU1	LDA   mount on d image m
 P  push mounted d to disc   Znn        wait for nn/10 s
 >  save sector to buffer    <  get sector from buffer
 Baddr set buffer to addr    /nn        repeat nn times
 CHad,by,by,...     change value at ad with by
 CAad,<string>      change at ad with string
 ?  prints this screen       ;   command separator
 Ld logon drive d            X  exit to CP/M            
 STOBU1
	CLC
	RTS


STODMA	LDY #0			;STORE BUFFER TO DMA
STODM1	LDA (BUFFER),Y
	STA (DMA),Y
	INY
	BNE STOD