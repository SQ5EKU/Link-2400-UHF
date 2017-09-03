' WERSJA DO DLUBANIA NA POJEDYNCZYCH BITACH :)
' Testowo-przykladowy program do sterowania PLL TBB206 w nadajniku RMT435A (LINK-2400 UHF)
' PCB-5V5
' TBB206 + zewnetrzny preskaler przez 64
' Wysylane sa identyczne dane jak w ukladzie fabrycznym (bez timeout'u)
' Fabryczna czestotliwosc pracy: 434.325 MHz simplex , krok PLL: 12.5kHz

' http://sq5eku.blogspot.com

'$regfile = "ATtiny2313.dat"
$regfile = "2313def.dat"

$crystal = 4915200                                          ' zegar 4.9152 MHz

Dim Tmp As Bit
Dim Data_s As Word
Dim Data_r As Long
Dim Data_tx As Long


Config Pinb.4 = Output                                      ' VCO
Config Pinb.5 = Output                                      ' PWR  LD1-czerwona , zalaczanie PA
Config Pind.0 = Output                                      ' DATA TBB206
Config Pind.1 = Output                                      ' CLK  TBB206 , TX na G7
Config Pind.2 = Output                                      ' LE   TBB206 , RX na G7
Config Pind.5 = Output                                      ' TST jako PTT
Config Pind.6 = Output                                      ' STS  LD2-zielona


Tbb_le Alias Portd.2                                        ' TBB206 pin 3 (LE)
Tbb_data Alias Portd.0                                      ' TBB206 pin 4 (DATA)
Tbb_clk Alias Portd.1                                       ' TBB206 pin 5 (CLOCK)
Ptt Alias Pind.5                                            ' PTT
Vco Alias Portb.4                                           ' VCO
Pwr Alias Portb.5                                           ' PA nadajnika , LED czerwona LD1

Declare Sub Tbb_tx
Declare Sub Tbb_r
Declare Sub Tbb_status
Declare Sub Le_pulse


Set Portd.5
Pwr = 0
Vco = 0
Tmp = 1
Tbb_le = 0
Tbb_data = 0
Tbb_clk = 0

'          |----STAT2---||adr|
Data_s = &B1010110011111_010                                ' 13 bitow konfiguracyjnych STATUS2 , 3 bity adresu


'          |-------R------||adr|                              12.8MHz : 12.5kHz = 1024 (16 bitow R)
Data_r = &B0000010000000000_100_0000000000000               ' 16 bitowy dzielnik R , 3 bity adresu rejestru R (100)


'                                                             434.325 MHz : 12.5kHz = 34746 (podzial N)
'           |--A--| |-----N----||adr|                         34746 / 64 = 542 , 34746 mod 64 = 58
Data_tx = &B0111010_001000011110_111_0000000000             ' 7 bitow A , 12 bitow N , 3 bity adresu rejestru N/A (111)

'                                                             432.500 MHz : 12.5kHz = 34600 (podzial N)
'           |--A--| |-----N----||adr|                         34746 / 64 = 540 , 34600 mod 64 = 40
'Data_tx = &B0101000_001000011100_111_0000000000             ' 14 bitow N , 2 bity adresu (23 bitowy rejestr N/A)

'-------------------------------------------------------------  glowna petla programu

Do
If Tmp = 0 Then
 If Ptt = 0 Then                                            ' jesli PTT wlaczone idz dalej
  Vco = 1                                                   ' wlacz VCO
  Gosub Tbb_status
  Gosub Tbb_r
  Gosub Tbb_tx
  Waitms 20
  Pwr = 1                                                   ' wlacz PA
  Tmp = 1
 End If
End If
If Tmp = 1 Then
 If Ptt = 1 Then
  Vco = 0                                                   ' wylacz VCO
  Pwr = 0                                                   ' wylacz PA
  Tmp = 0
 End If
End If

Loop
End

'-------------------------------------------------------------  koniec glownej petli programu

Tbb_status:
 Shiftout Tbb_data , Tbb_clk , Data_s , 1                   ' wyslij 16 bitow
 Gosub Le_pulse
 Return

Tbb_r:
 Shiftout Tbb_data , Tbb_clk , Data_r , 1 , 19              ' wyslij 19 bitow
 Gosub Le_pulse
 Return

Tbb_tx:
Shiftout Tbb_data , Tbb_clk , Data_tx , 1 , 22              ' wyslij 22 bity
Gosub Le_pulse

Le_pulse:
 nop
 Tbb_le = 1
 nop
 Tbb_le = 0
 Return