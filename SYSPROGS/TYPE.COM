�3�" \!���� �[ � � � �;� � ��� � � � �#� ���+��'��4�
��	�F�) f!� �������
 � ��� L� �a�" \!� L� ��8�� ��Т�$�H� � hLG ��  f!�)���� ���� � 8i@��"�E��y�" \!� �  X!`� ���������/�������� ݣ!������� �`轣!�`� X!�ۅ�!�� ���)�� k!�� k!L! k!H 5! k!��� \!h	 t!�` L!8`� J����������!� f!������! \!� �!�0�"�	L�  d!� �L� ������`���! \!� � �y��Y�`8`HJJJJ �!h)�
�ii0 f!`P�p� Error $ 
Retry  (Y/N) ?  BIOS BDOS CCP  RSX  USER ��Drive not ready �Invalid Drive ݂File not found �Invalid FCB �Filename missing  
 
TYPE V1.7      (c) D.Lausberg 3.11.1991

 
*** EOF reached ***
 
Insert disc to drive B:
and press any key 
 
ERRTAB  DB $FD,$81,'Drive not ready',EOT
	DB $F9,$01,'Invalid Drive',EOT
	DB $DD,$8