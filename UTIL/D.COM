�5�$ ]# � �� � � �"��)�  }!�� ��� ��  �!���� � ����� �"�𩹠$ ]#�� � � L�  �"��
�Ԡ$ ]#LC  �  �"�X�$ ]# �! �!L�  �!��	 �!���� I"���$ ]# " �"���$ ]#LC � ���� �" � � �"`� � �iA��$� ���$Hi@��$�E���$ ]#� �  Y#h8�� � �����` %!� ���ȱ� <!�� ��	ȱ�
 U!L
!$0�`���
��%i ��i���`8������%�����`� ȱ�	�0�	��
�`�0�`�� ������`�� �ȥ��e���`� ��ȱ�`���` �! �!���L" I"L�!� � �" �" �" �" e# �!� 8"�. g#� 8" b#��� ��� ��J&����8i e���`��He���hL�!���	��&��Ff����`�� � g# �!���`� �� �#�� �#�)HFfFfFfh������ �"��	� b# b#`� Y#`���� �����&�e��e��e����ؠ�  �#��`
H�0��1 g#h`���'����%�`���� �	�?������`� Y#���#�� ���)�� l#�� l#L# l#H 6# l#��� ]#h	 u#�` M#8`� J����������#� g#������# ]#� �#�2�$�	L�  e#� �L� ������`���# ]#� � �y��Y�8``HJJJJ �#h)$0� ����
�ii0 g#` Error $ 
Retry  (Y/N) ?  BIOS BDOS CCP  RSX  USER ��Drive not ready �Invalid Drive ݂File not found �File exists �Invalid FCB  
 
D.COM V2.3      (c) D.Lausberg
 
Attr filename.ext   rec    kB    Attr filename.ext   rec    kB
 

total diskspace used   kB 

Directory finished

 
no file
 
Insert disc to drive B:
and press any key 
 FINDP),Y
	DEY
	BPL SWDIRL
	LDA #$FF
	STA EX_FLAG		;switch occurred
	RTS


SavBDP	LDA BUFPNT		;save BUFPNT to BUFDIR & INC BUFINDP
	LDY #0
	STA (BUFINDP),Y
	INY
	LDA BUFPNT+1
	STA (BUFINDP),Y
INCBIP	CLC			;BUFINDP+2
	LDA #2
	