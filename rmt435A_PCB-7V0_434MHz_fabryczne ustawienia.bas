' WERSJA DO DLUBANIA NA POJEDYNCZYCH BITACH :)
' Testowo-przykladowy program do sterowania PLL PMB2306T w nadajniku RMT435A (LINK-2400 UHF)
' PCB-7V0
' PMB2306T + zewnetrzny preskaler przez 64
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
Config Pind.0 = Output                                      ' DATA PMB2306T
Config Pind.1 = Output                                      ' CLK  PMB2306T , TX na G7
Config Pind.2 = Output                                      ' LE   PMB2306T , RX na G7
Config Pind.5 = Output                                      ' TST jako PTT
Config Pind.6 = Output                                      ' STS  LD2-zielona


Pmb_le Alias Portd.2                                        ' PMB2306 pin 3 (LE)
Pmb_data Alias Portd.0                                      ' PMB2306 pin 4 (DATA)
Pmb_clk Alias Portd.1                                       ' PMB2306 pin 5 (CLOCK)
Ptt Alias Pind.5                                            ' PTT
Vco Alias Portb.4                                           ' VCO
Pwr Alias Portb.5                                           ' PA nadajnika , LED czerwona LD1

Declare Sub Pmb_tx
Declare Sub Pmb_r
Declare Sub Pmb_status
Declare Sub Le_pulse


Set Portd.5
Pwr = 0
Vco = 0
Tmp = 1
Pmb_le = 0
Pmb_data = 0
Pmb_clk = 0

'          |----STAT2---| ||adr
Data_s = &B01111101011101_01                                ' 14 bitow konfiguracyjnych STATUS2 , 2 bity adresu
'
'          |-------R------| ||adr                             12.8MHz : 12.5kHz = 1024 (16 bitow R)
Data_r = &B0000010000000000_11_00000000000000               ' 16 bitowy dzielnik R , 2 bity adresu (18 bitowy rejestr R)
'
'                                                             434.325 MHz : 12.5kHz = 34746 (podzial N)
'           |--A--| |-----N------| ||adr                      34746 / 64 = 542 , 34746 mod 64 = 58
Data_tx = &B0111010_00001000011110_10_000000000             ' 14 bitow N , 2 bity adresu (23 bitowy rejestr N/A)

'                                                             432.500 MHz : 12.5kHz = 34600 (podzial N)
'           |--A--| |-----N------| ||adr                      34746 / 64 = 540 , 34600 mod 64 = 40
'Data_tx = &B0101000_00001000011100_10_000000000             ' 14 bitow N , 2 bity adresu (23 bitowy rejestr N/A)

'-------------------------------------------------------------  glowna petla programu

Do
If Tmp = 0 Then
 If Ptt = 0 Then                                            ' jesli PTT wlaczone idz dalej
  Vco = 1                                                   ' wlacz VCO
  Gosub Pmb_status
  Gosub Pmb_r
  Gosub Pmb_tx
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

Pmb_status:
 Shiftout Pmb_data , Pmb_clk , Data_s , 1                   ' wyslij 16 bitow
 Gosub Le_pulse
 Return

Pmb_r:
 Shiftout Pmb_data , Pmb_clk , Data_r , 1 , 18              ' wyslij 18 bitow
 Gosub Le_pulse
 Return

Pmb_tx:
 Shiftout Pmb_data , Pmb_clk , Data_tx , 1 , 23             ' wyslij 23 bity
 Gosub Le_pulse
 Return

Le_pulse:
 nop
 Pmb_le = 1
 nop
 Pmb_le = 0
 Return