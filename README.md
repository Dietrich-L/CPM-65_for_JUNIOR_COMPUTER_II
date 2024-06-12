<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=windows-1252">
    <link rel="alternate stylesheet" type="text/css" href="resource://gre-resources/plaintext.css">
  </head>
  <body>
    <pre>CPM-65 Junior Computer II Port
===========
Dietrich Lausberg <lausbergd@gmail.com>
https://github.com/dietrich-l

This repository contains the Junior Computer II Port of CPM-65, <br>a CP/M-80 analogue operating system for 6502 based microcomputers
<br>![4_BOOT](https://github.com/Dietrich-L/CPM-65_for_JUNIOR_COMPUTER_II/assets/83355183/2ed79c93-dfbe-426f-b827-fa08cdfe25a0)
<br>System Requirements
--------------------------

Junior Computer II
Expansion Card

Special thanks for support and testing goes to <br>Joerg Walke, Developer of the Junior Computer II system, Norbert J. and Edzard

<br>&nbsp; System Structure
--------------------

CPM-65 consists of 3 layers:

- BIOS Basic I/O system - Drives can be A-D non consecutive. 
- BDOS Basic disc operating system - this is the CPM-65 kernal. Size 2 kB
- CCP Console command program - a simple console which only allows to invoke CPM-65 programs. <br>      No resident commands. Size 1 kB<br><br>On the JC ][ CPM-65 resides on 1 MB images on a SD card. Upon Boot the JC ][ first executes a <br>program in BOOT.SYS in the root directory of the SD. BOOT.SYS offers all bootable images found <br>in the Root directory for booting. The images must have the CPM-65 system in sectors 1 to 11.<br>The program then loads CPM-65 to memory, mounts the selected image as Drive A: via a BIOS call<br>and starts the CCP. Up to 4 images can be mounted with the utility SD-UTIL. <br>A more detailed description how to prepare a bootable SD card can be found <br>under [docs/CPM-65 JC-II BOOT preparations.txt](https://github.com/Dietrich-L/CPM-65_for_JUNIOR_COMPUTER_II/blob/master/docs/CPM-65%20JC-II%20BOOT%20preparations.txt)<br>

<br> &nbsp;File &amp; Disc Format
----------------------

Filenames are CP/M-style d:filename.ext with d &lt;Drive A-D&gt;
Programs must have .COM as extension and are loaded to $2000 and started there.

The directory structure is nearly CP/M-compatible. Disk images can be read with appropriate  tools <br>like CPMTOOLS, <a
href="https://github.com/ProgrammingHobby/CPM_Image-File_Explorer">CIFE (CPM Image File Explorer)</a> or CpmtoolsGUI. A disdefs file is in the IMAGES section. 

The Disc format is 128 tracks/ 32 sectors/ 256 byte/sector. <br>It is defined in the BIOS. The BDOS operates on sector numbers. 
<br>
</pre><a title="Software List" a=""> Software List
      <table style="width: 809px;" border="1">
        <tbody>
          <tr>
            <td style="width: 140.383px;"><span style="font-family: Courier New,Courier,monospace;">Program<br>
              </span></td>
            <td style="margin-left: 90px; width: 83.65px;"><span style="font-family: Courier New,Courier,monospace;">Version<br>
              </span></td>
            <td style="width: 575px; margin-left: -100px;"><span style="font-family: Courier New,Courier,monospace;">Description<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">ALLOC<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">2.9<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">shows
                disc allocation map<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">ASM<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">2.8<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">native
                6502 Assembler<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BASIC<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.6<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">Microsoft
                Basic interpreter<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BDOS<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">2.4<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">CPM-65
                BDOS<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BIOS<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.1<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">JC II
                CPM-65 BIOS</span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BOOT<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.3<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">JC II
                CPM-65 BOOT program in track 0, sector 0<br>
              </span></td>
          </tr>
           <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BOOTSYS<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.8<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">JC II
                CPM-65 BOOT program on SD, main directory<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">BROWSE<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.2<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">text
                file browser<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">CCP<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.5<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">CPM-65
                CCP<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">COPY<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.4<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">multi
                file copy utility<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">D<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">2.3<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">show
                directory alphabetically sorted<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">DEBUG<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.9<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">Debugger,
                8 breakpoints, stepping, disassembler,...<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">DUTIL<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.5<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">disc
                sector editor<br>
              </span></td>
          </tr>
          <tr>
            <td style="height: 28.8167px;"><span style="font-family: Courier New,Courier,monospace;">EDIT<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.1<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">Simple
                editor for text files &amp; FORTH screens<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">ERASE<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.5<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">erase
                files<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">FDISK<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.0<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">Disk
                initializer<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">FORTH<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.6<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">FIG
                FORTH including module for standalone applications<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">RENAME<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.1<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">rename
                files<br>
              </span></td>
          </tr>
          <tr>
            <td><a title="CIFE"><span style="font-family: Courier New,Courier,monospace;">SD-UTIL</span></a></td>
            <td><a title="CIFE"><span style="font-family: Courier New,Courier,monospace;">1.5</span></a></td>
            <td><a title="CIFE"><span style="font-family: Courier New,Courier,monospace;">SD
                  utility for image handling and sector inspection<br>
                </span></a></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">SYS<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.6<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">puts
                code for BOOT, BIOS, BDOS, CCP into the system tracks<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">SYSGEN<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.0<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">copy
                operating system to another disc<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">TYPE<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">1.7<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">prints
                text file to screen<br>
              </span></td>
          </tr>
          <tr>
            <td><span style="font-family: Courier New,Courier,monospace;">XMODEM<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">2.3<br>
              </span></td>
            <td><span style="font-family: Courier New,Courier,monospace;">File transfer XMODEM protocol, via serial I/O 19200 Baud<br>
              </span></td>
          </tr>
        </tbody>
      </table>
      &nbsp; <br>
      All software is supplied as assembler files to be assembled with the
      CPM-65 assembler. <br>
    </a>
    <p><a title="Software List" a=""> In case you wish to use a different
        assembler, the syntax has to be adapted accordingly. <br>
      </a></p>
    <p><a title="Software List" a=""> Documentation <br>
      </a></p>
    <p><a title="Software List" a="">-------------------- <br>
      </a></p>
    <p><a title="Software List" a="">Currently the documentation of CPM-65 is
        sparse and only for my personal needs. </a></p>
    <p><a title="Software List" a=""> I plan to write appropriate docs over
        time. If there are any whishes, please open a DISCUSSION <br>
      </a></p>
    <p><a title="Software List" a=""> Errors</a></p>
    <p><a title="Software List" a=""> -------------------- <br>
      </a></p>
    <p><a title="Software List" a="">The Junior Computer II port of CPM-65 is
        now in V1.0 and reasonably stable. Please report errors and crashes in the ISSUE section <br>
      </a></p>
    <p><a title="Software List" a="">The CPM-65 system itself has now seen more
        than 30 years of service. Currently there are no known errors. <br>
      </a></p>
    <p><a title="Software List" a="">However, since an error free software does
        not exist, please report any errors in the ISSUE section <br>
      </a></p>
    <p><a title="Software List" a="">Other related systems <br>
      </a></p>
    <p><a title="Software List" a="">--------------------- <br>
      </a></p>
    <p><a title="Software List" a="">When I started the development of cpm-65, I
        was blissfully unaware of any other aproaches. </a></p>
    <p><a title="Software List" a=""> However there are some, most notably:</a></p>
    <p><a title="Software List" a=""> - DOS/65 by Richard Leary. There is a
        limited compatibility</a></p>
    <p><a title="Software List" a=""> - OUP/M by Jiang - Xiong Shao. Published
        1983, no further development</a></p>
    <p><a title="Software List" a=""> - CPM65 by David Given, published 2022 <br>
      </a></p>
    <p><a title="Software List" a=""> Redistribution <br>
      </a></p>
    <p><a title="Software List" a="">-------------- <br>
      </a></p>
    <p><a title="Software List" a=""> Source code, and all documents, are freely
        redistributable in any form. <br>
      </a></p>
    <p><a title="Software List" a="">Please see the the COPYRIGHT file included
        in this Repository. </a> </p>
  </body>
</html>
