���$ �# � �� � � H#��)�  �!�� ��� ��  �!���� � ����� H#��7�% �#�� � � L�  �"��
�R�% �#LC  ! �"�֠$ �# �! �!L�  �!��	 �!���� R"��% �# &" �"�3�% �#LC � ������ �" � � �" #`� � �iA�u%� ���"Hi@�u%�E��^�% �# �  �#h8�� � �����`��L�  1!� ���ȱ� H!�� ��	ȱ�
 a!L!$0�`���
��%i ��i����`8������%������`� ȱ�	�0�	��
�`�0�`�� ������`�� �ȥ��e���`� ��ȱ�`���` �! �!���L" R"� � �" �" �" �" �# �!� A"�. �#� A" �#��� ��� ��J&����8i e���`��He���hL�!���	��&��Ff����`�� � �# �!���`� �� �#�� �#�)HFfFfFfh������ �"��	� �# �#`����$H � h �#`���� �����&�e��e��e����ؠ�  �#��`
H�0��1 �#h`����'�����%�`����/�� �	�?������`� ���������/�������� �$������� �`�$�`� �#�9��$�� ���)�� �#�� �#LY# �#H �# �#��� �#h	 �#�` �#8`� J��������� $� �#�����$ �#� �#���$�	L�  �#� �L� ������`��$ �#� � �y��Y�8``HJJJJ �#h)$0� ����
�ii0 �#`P�p� Error $ 
Retry  (Y/N) ?  BIOS BDOS CCP  RSX  USER ��Drive not ready �Invalid Drive ݂File not found �File exists �Invalid FCB  
 
D.COM V2.4      (c) D.Lausberg
Usage d [d:][filename.ext][/p(ause)]]
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
 Check for last entry
	CMP BUFINDP+1
	BNE DECBIP2
	LDA #BUFDIR
	CMP BUFINDP
	BNE DECBIP2
	CLC
DECBIP2	RTS			