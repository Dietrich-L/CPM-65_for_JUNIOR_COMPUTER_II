 %  > �Ơ) �'�
 � � �  n ��Ʉ�� 'L � �Q� ��������^� �%`���) �'` \ H� \ H� i h i h i `� 8�
����i
`	0L�' �%�)�;� �%� � ���'��������ȹ�'Hȹ�'H`��8`�  F&�&�ڠ) �'�")? �'�: �'�! �'�: �'�  �' }'`�# O&�0��) �'�# P$�$ �'�. �'�%) �'�. �'�  �'�& �' }'` =%�)�  =%��!�"��#�	�$�  '` �$�*)� =%�!� =%��� �%�� &�
� &� �&` �$�A)� =%�8� =%�1�� �%�(� &�!� &� /&� �'���, �' �'L! 9&` �$�))� =%� �� =%�����e��	�e� �#` �$� )� =%��� =%���������8`��e��	�e� �#` �%�'���) �'� � �'� �'� �%�� �'�� }'` �'�
 �' �'�8* �' }'L(" =%��	�` �%�
�H��A�(��8` =%���� =%�� ������暑8`Ɂ��` =%�Մ� �%�̠ ������暑8` =%���Ɂ�4���	��)�� =%���Ɂ��i���i � u$ �$�� �$`8` �$�  =%��� =%� �$�� �������` �$�_ =%�Z�� =%�Q���������	�����`�H�H� �������������������LN#h�h�`�  � ��* �'` %���
��N������������`��
��� � ` %�
�� �멂8`Ɂ���
��ݩ�8`� �%�'� �%� � &� �$� /&�� ������� 9&`� �%�)� �%�"� � &������� �$�	 �&� �%`�)�� �&� �%��`�i���`�Hȱ�h`)�����	ȹn)�����ȹn)� �'La$���) �'` �$�: �' �'` }'� �'� �'` }'� � �$���� �'���� � �$����� �$ �$`�����`e���`����` �'�  �'`)� ����. �'` =%�Ɂ�������`8` =%�')�
��
�)�JHe
�
hJJe
���0id����8`�
`� ��� x%�	������8`� �� ��Ʉ��;�쩁8`�;��,�Ʉ�ܥ�` �%��0��:��A��G�8`i	)�&&����`� � � ����� �%`��`�a��~�)_` �& �& �&�	 �&��� �&L�&
�Q�� �&�Q &����`��  Hȹ   &h� &`8*� �&� &`�P �& '� �&P� �& �&���L�& �& �&�P` �& �& �&�P`�B��ALU&�B��A�h �%�+� �A��� &��h &� /&��B� �B�A�� 9&�B� `� �P �&� ' �&&P '���` �& ' �& '` �& ' �&` �& �& �&` �& �&` �& ' �& '`��)�`��	��`��)���
`��)��	�`��)��`��	�``� �% }'�+��(�� ���)�� �'�� �'L*' �'H Z' �'��� �'h	 �'�` q'8`� J���������(� �'������' �'� �'�Ҡ)�	L�  �'� �L� ������`��( �'� �  �%�Y�`8`HJJJJ �'h)�
�ii0 �'`Z �K �S!"G!RR!�W!�B"IC"SF"�M#D"�I"X#t?#yZ#�/#�  Error $ 
Retry (Y/N) ?  BIOS BDOS CCP  RSX  USER �Invalid Drive ނDirectory full ݂File not found �File exists �Invalid FCB ؂Disk full ւFile is R/O �I2C illegal function call �ID not found �Argument = 0 �Address overlap in move �Device not responding �I2C Bus Error �End of Line �Too Much Parameters �Illegal Parameter �Missing Parameter �Unknown Command  Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag , den  
I2C-Utility   V1.5 
Command >      
 
 Uhrzeit:  
   Datum:  
 I2C devices active
 dev   W   R
    I2C-Utility V1.5                    (c) 3.7.2021
Command Summary:
 K  display date              Z   display time
 Baddr  set buffer to addr    Sdv,rg,by  set dev, reg, byte
 Gdv,rg,nn  get nn bytes from dev, reg 
 Rdv,regw,nnnn  read from dev, reg16, nnnn bytes to buffer
 Wdv,regw,nnnn  write to  dev, reg16, nnnn bytes from buffer
 CHad,by,by,...     change value at ad with by
 CAad,<string>      change at ad with string
 Mn,m,j     move to n from m,j
 Dnnnn,mmmm dump memory       Fnnnn,mmmm,cc fill memory
 I  info I2C devs active      /nn repeat nn times
 ?  prints this screen        ;   command separator
 X  exit to CP/M             
 	BCS CHANGX
	LDY #0
	STA (PNT),Y	;REPLACE
	INC PNT
	BNE CASC1
	INC PNT+1
